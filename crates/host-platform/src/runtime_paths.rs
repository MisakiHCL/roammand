// SPDX-License-Identifier: MPL-2.0

use std::path::{Path, PathBuf};

use crate::{RestrictedFsError, ensure_private_directory};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RuntimePaths {
    data_dir: PathBuf,
    runtime_dir: PathBuf,
}

impl RuntimePaths {
    #[must_use]
    pub fn from_roots(data_dir: PathBuf, runtime_dir: PathBuf) -> Self {
        Self {
            data_dir,
            runtime_dir,
        }
    }

    #[must_use]
    pub fn data_dir(&self) -> &Path {
        &self.data_dir
    }

    #[must_use]
    pub fn runtime_dir(&self) -> &Path {
        &self.runtime_dir
    }

    /// Creates and restricts the data and runtime roots.
    ///
    /// # Errors
    ///
    /// Returns an error when either root cannot be created as a private
    /// directory.
    pub fn prepare(&self) -> Result<(), RestrictedFsError> {
        ensure_private_directory(&self.data_dir)?;
        ensure_private_directory(&self.runtime_dir)?;
        Ok(())
    }
}
