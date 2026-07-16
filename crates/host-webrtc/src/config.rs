// SPDX-License-Identifier: MPL-2.0

pub const DATA_CHANNEL_INPUT_RELIABLE: &str = "input.reliable";
pub const DATA_CHANNEL_POINTER_FAST: &str = "pointer.fast";

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum VideoCodec {
    H264,
    Vp8,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum IceTransportPolicy {
    All,
    Relay,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DataChannelReliability {
    OrderedReliable,
    UnorderedNoRetransmits,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct DataChannelConfig {
    pub label: &'static str,
    pub reliability: DataChannelReliability,
}

const CODEC_PREFERENCES: [VideoCodec; 2] = [VideoCodec::H264, VideoCodec::Vp8];
const DATA_CHANNELS: [DataChannelConfig; 2] = [
    DataChannelConfig {
        label: DATA_CHANNEL_INPUT_RELIABLE,
        reliability: DataChannelReliability::OrderedReliable,
    },
    DataChannelConfig {
        label: DATA_CHANNEL_POINTER_FAST,
        reliability: DataChannelReliability::UnorderedNoRetransmits,
    },
];

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SessionConfig {
    ice_transport_policy: IceTransportPolicy,
}

impl SessionConfig {
    #[must_use]
    pub const fn new(ice_transport_policy: IceTransportPolicy) -> Self {
        Self {
            ice_transport_policy,
        }
    }

    #[must_use]
    pub const fn codec_preferences(&self) -> &[VideoCodec] {
        &CODEC_PREFERENCES
    }

    #[must_use]
    pub const fn ice_transport_policy(&self) -> IceTransportPolicy {
        self.ice_transport_policy
    }

    #[must_use]
    pub const fn data_channels(&self) -> &[DataChannelConfig] {
        &DATA_CHANNELS
    }
}
