// SPDX-License-Identifier: Apache-2.0

use sha2::{Digest, Sha256};

const MAGIC: &[u8; 4] = b"PRDT";
const VERSION: u16 = 1;
const HEADER_LENGTH: usize = 10;
const FIELD_HEADER_LENGTH: usize = 6;
const MAX_FIELDS: usize = 16;
const MAX_FIELD_LENGTH: usize = 1024;
const MAX_TRANSCRIPT_LENGTH: usize = 4096;

#[derive(Debug, Clone, Copy, Eq, PartialEq)]
#[repr(u16)]
pub enum TranscriptPurpose {
    PairingSas = 1,
    SessionOffer = 2,
    SessionAnswer = 3,
    SessionReconnect = 4,
}

impl TryFrom<u16> for TranscriptPurpose {
    type Error = TranscriptError;

    fn try_from(value: u16) -> Result<Self, Self::Error> {
        match value {
            1 => Ok(Self::PairingSas),
            2 => Ok(Self::SessionOffer),
            3 => Ok(Self::SessionAnswer),
            4 => Ok(Self::SessionReconnect),
            _ => Err(TranscriptError::UnknownPurpose),
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct TranscriptField {
    pub tag: u16,
    pub value: Vec<u8>,
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct CanonicalTranscript {
    pub purpose: TranscriptPurpose,
    pub fields: Vec<TranscriptField>,
}

#[derive(Debug, Clone, Copy, Eq, PartialEq)]
pub enum TranscriptError {
    InvalidMagic,
    UnknownVersion,
    UnknownPurpose,
    TooManyFields,
    DuplicateField,
    FieldOrder,
    FieldTooLong,
    TranscriptTooLong,
    UnknownField,
    MissingField,
    InvalidFieldLength,
    Truncated,
    TrailingBytes,
}

impl TranscriptError {
    #[must_use]
    pub const fn wire_name(self) -> &'static str {
        match self {
            Self::InvalidMagic => "bad_magic",
            Self::UnknownVersion => "unknown_version",
            Self::UnknownPurpose => "unknown_purpose",
            Self::TooManyFields => "too_many_fields",
            Self::DuplicateField => "duplicate_field",
            Self::FieldOrder => "field_order",
            Self::FieldTooLong => "field_too_long",
            Self::TranscriptTooLong => "transcript_too_long",
            Self::UnknownField => "unexpected_field",
            Self::MissingField => "missing_field",
            Self::InvalidFieldLength => "invalid_field_length",
            Self::Truncated => "truncated",
            Self::TrailingBytes => "trailing_bytes",
        }
    }
}

/// Encodes a transcript using the Canonical Transcript V1 byte format.
///
/// # Errors
///
/// Returns a [`TranscriptError`] when fields violate the purpose contract or a
/// protocol size limit.
pub fn encode(transcript: &CanonicalTranscript) -> Result<Vec<u8>, TranscriptError> {
    validate_fields(transcript.purpose, &transcript.fields)?;
    let encoded_length = transcript
        .fields
        .iter()
        .fold(HEADER_LENGTH, |length, field| {
            length + FIELD_HEADER_LENGTH + field.value.len()
        });
    if encoded_length > MAX_TRANSCRIPT_LENGTH {
        return Err(TranscriptError::TranscriptTooLong);
    }

    let mut output = Vec::with_capacity(encoded_length);
    output.extend_from_slice(MAGIC);
    output.extend_from_slice(&VERSION.to_be_bytes());
    output.extend_from_slice(&(transcript.purpose as u16).to_be_bytes());
    output.extend_from_slice(
        &u16::try_from(transcript.fields.len())
            .map_err(|_| TranscriptError::TooManyFields)?
            .to_be_bytes(),
    );
    for field in &transcript.fields {
        output.extend_from_slice(&field.tag.to_be_bytes());
        output.extend_from_slice(
            &u32::try_from(field.value.len())
                .map_err(|_| TranscriptError::FieldTooLong)?
                .to_be_bytes(),
        );
        output.extend_from_slice(&field.value);
    }
    Ok(output)
}

/// Decodes and validates Canonical Transcript V1 bytes.
///
/// # Errors
///
/// Returns a [`TranscriptError`] when the input is malformed, non-canonical,
/// or outside the protocol limits.
pub fn decode(bytes: &[u8]) -> Result<CanonicalTranscript, TranscriptError> {
    if bytes.len() > MAX_TRANSCRIPT_LENGTH {
        return Err(TranscriptError::TranscriptTooLong);
    }

    let mut reader = Reader::new(bytes);
    if reader.read_exact(MAGIC.len())? != MAGIC {
        return Err(TranscriptError::InvalidMagic);
    }
    if reader.read_u16()? != VERSION {
        return Err(TranscriptError::UnknownVersion);
    }
    let purpose = TranscriptPurpose::try_from(reader.read_u16()?)?;
    let field_count = usize::from(reader.read_u16()?);
    if field_count > MAX_FIELDS {
        return Err(TranscriptError::TooManyFields);
    }

    let mut fields = Vec::with_capacity(field_count);
    let mut previous_tag = None;
    for _ in 0..field_count {
        let tag = reader.read_u16()?;
        if previous_tag == Some(tag) {
            return Err(TranscriptError::DuplicateField);
        }
        if previous_tag.is_some_and(|previous| tag < previous) {
            return Err(TranscriptError::FieldOrder);
        }
        previous_tag = Some(tag);

        let length =
            usize::try_from(reader.read_u32()?).map_err(|_| TranscriptError::FieldTooLong)?;
        if length > MAX_FIELD_LENGTH {
            return Err(TranscriptError::FieldTooLong);
        }
        fields.push(TranscriptField {
            tag,
            value: reader.read_exact(length)?.to_vec(),
        });
    }

    if !reader.is_finished() {
        return Err(TranscriptError::TrailingBytes);
    }
    validate_fields(purpose, &fields)?;
    Ok(CanonicalTranscript { purpose, fields })
}

#[must_use]
pub fn sha256(bytes: &[u8]) -> [u8; 32] {
    Sha256::digest(bytes).into()
}

fn validate_fields(
    purpose: TranscriptPurpose,
    fields: &[TranscriptField],
) -> Result<(), TranscriptError> {
    if fields.len() > MAX_FIELDS {
        return Err(TranscriptError::TooManyFields);
    }

    let required_tags = required_tags(purpose);
    let mut previous_tag = None;
    for field in fields {
        if previous_tag == Some(field.tag) {
            return Err(TranscriptError::DuplicateField);
        }
        if previous_tag.is_some_and(|previous| field.tag < previous) {
            return Err(TranscriptError::FieldOrder);
        }
        previous_tag = Some(field.tag);

        if field.value.len() > MAX_FIELD_LENGTH {
            return Err(TranscriptError::FieldTooLong);
        }
        if !required_tags.contains(&field.tag) {
            return Err(TranscriptError::UnknownField);
        }
        if field.value.len() != field_length(field.tag) {
            return Err(TranscriptError::InvalidFieldLength);
        }
    }

    if fields.len() < required_tags.len() {
        return Err(TranscriptError::MissingField);
    }
    if fields.len() > required_tags.len() {
        return Err(TranscriptError::UnknownField);
    }
    if fields
        .iter()
        .zip(required_tags)
        .any(|(field, required_tag)| field.tag != *required_tag)
    {
        return Err(TranscriptError::MissingField);
    }
    Ok(())
}

const fn required_tags(purpose: TranscriptPurpose) -> &'static [u16] {
    match purpose {
        TranscriptPurpose::PairingSas => &[1, 2, 3, 4, 5, 6, 7],
        TranscriptPurpose::SessionOffer => &[1, 2, 8, 9, 10, 11, 12, 13, 14],
        TranscriptPurpose::SessionAnswer => &[1, 2, 8, 9, 10, 11, 12, 13, 14, 15, 16],
        TranscriptPurpose::SessionReconnect => &[1, 2, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    }
}

const fn field_length(tag: u16) -> usize {
    match tag {
        3 | 8 => 16,
        10 | 11 => 8,
        12 | 17 => 4,
        _ => 32,
    }
}

struct Reader<'a> {
    bytes: &'a [u8],
    offset: usize,
}

impl<'a> Reader<'a> {
    const fn new(bytes: &'a [u8]) -> Self {
        Self { bytes, offset: 0 }
    }

    fn read_u16(&mut self) -> Result<u16, TranscriptError> {
        let bytes: [u8; 2] = self
            .read_exact(2)?
            .try_into()
            .map_err(|_| TranscriptError::Truncated)?;
        Ok(u16::from_be_bytes(bytes))
    }

    fn read_u32(&mut self) -> Result<u32, TranscriptError> {
        let bytes: [u8; 4] = self
            .read_exact(4)?
            .try_into()
            .map_err(|_| TranscriptError::Truncated)?;
        Ok(u32::from_be_bytes(bytes))
    }

    fn read_exact(&mut self, length: usize) -> Result<&'a [u8], TranscriptError> {
        let end = self
            .offset
            .checked_add(length)
            .filter(|end| *end <= self.bytes.len())
            .ok_or(TranscriptError::Truncated)?;
        let value = &self.bytes[self.offset..end];
        self.offset = end;
        Ok(value)
    }

    const fn is_finished(&self) -> bool {
        self.offset == self.bytes.len()
    }
}
