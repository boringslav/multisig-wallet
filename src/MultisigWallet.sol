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

contract MultisigWallet {
    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(address indexed owner, uint256 indexed txId);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    address[] public s_owners;
    mapping(address => bool) public s_isOwner;
    uint256 public s_approvalsRequired;
    Transaction[] public s_transactions;
    // txId => owner => approved
    mapping(uint256 => mapping(address => bool)) public s_approved;

    modifier onlyOwner() {
        if (!s_isOwner[msg.sender]) revert MultisigWallet__NotOwner();
        _;
    }

    modifier txExists(uint256 _txId) {
        if (_txId >= s_transactions.length) {
            revert MultisigWallet__Invalid_Tx();
        }
        _;
    }

    modifier notApproved(uint256 _txId) {
        if (s_approved[_txId][msg.sender]) revert MultisigWallet__Tx_Already_Approved();
        _;
    }

    modifier notExecuted(uint256 _txId) {
        if (s_transactions[_txId].executed) revert MultisigWallet__Tx_Alreadey_Executed();
        _;
    }

    constructor(address[] memory _owners, uint256 _approvalsRequired) {
        if (_owners.length == 0) revert MultisigWallet__Invalid_Owners_Count();
        if (_approvalsRequired == 0 || _approvalsRequired > _owners.length) {
            revert MultisigWallet__Invalid_Required_Approvals();
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) revert MultisigWallet__Zero_Address();
            if (s_isOwner[owner]) revert MultisigWallet__Owner_Not_Unique();
            s_isOwner[owner] = true;
            s_owners.push(owner);
        }

        s_approvalsRequired = _approvalsRequired;
    }

    function submit(address _to, uint256 _value, bytes calldata data) external onlyOwner {
        s_transactions.push(Transaction({to: _to, value: _value, data: data, executed: false}));
        emit Submit(s_transactions.length - 1);
    }

    function approve(uint256 _txId) external onlyOwner txExists(_txId) notApproved(_txId) {
        s_approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint256 _txId) private view returns (uint256 count) {
        for (uint256 i; i < s_owners.length; i++) {
            if (s_approved[_txId][s_owners[i]]) {
                count += 1;
            }
        }
    }

    function execute(uint256 _txId) external txExists(_txId) notExecuted(_txId) {
        if (_getApprovalCount(_txId) < s_approvalsRequired) revert MultisigWallet__Invalid_Tx();
        Transaction storage transaction = s_transactions[_txId];
        transaction.executed = true;

        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);

        if (!success) revert MultisigWallet__Tx_Failed(_txId);
        emit Execute(msg.sender, _txId);
    }

    function revoke(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        if (!s_approved[_txId][msg.sender]) revert MultisigWallet__Tx_Not_Approved(_txId);
        s_approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}
