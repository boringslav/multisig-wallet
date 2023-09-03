// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

error MultisigWallet__Invalid_Owners_Count();
error MultisigWallet__Invalid_Required_Approvals();
error MultisigWallet__Zero_Address();
error MultisigWallet__Owner_Not_Unique();
error MultisigWallet__NotOwner();
error MultisigWallet__Invalid_Tx();
error MultisigWallet__Tx_Already_Approved();
error MultisigWallet__Tx_Alreadey_Executed();
error MultisigWallet__Tx_Not_Approved(uint256 _txId);
error MultisigWallet__Tx_Failed(uint256 _txId);
