// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DigitalWill {
    address public owner;
    address public beneficiary;
    string private encryptedWillHash;
    uint256 public lastAliveTimestamp;
    uint256 public inactivityPeriod = 365 days;

    mapping(address => uint256) public shares;
    address[] public beneficiaryList;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    event AlivePing(uint256 timestamp);
    event EncryptedWillUpdated(string ipfsHash);
    event BeneficiaryUpdated(address recipient, uint256 share);
    event BeneficiaryRemoved(address recipient);
    event BeneficiariesReset();

    constructor() {
        owner = msg.sender;
        lastAliveTimestamp = block.timestamp;
    }

    function iAmAlive() external onlyOwner {
        lastAliveTimestamp = block.timestamp;
        emit AlivePing(lastAliveTimestamp);
    }

    function isInactive() public view returns (bool) {
        return block.timestamp > lastAliveTimestamp + inactivityPeriod;
    }

    function setEncryptedWill(string calldata _ipfsHash) external onlyOwner {
        encryptedWillHash = _ipfsHash;
        emit EncryptedWillUpdated(_ipfsHash);
    }

    function getEncryptedWill() external view returns (string memory) {
        return encryptedWillHash;
    }

    function addTokenBeneficiary(address _recipient, uint256 _share) external onlyOwner {
        if (shares[_recipient] == 0) {
            beneficiaryList.push(_recipient);
        }
        shares[_recipient] = _share;
        emit BeneficiaryUpdated(_recipient, _share);
    }

    function removeBeneficiary(address _recipient) external onlyOwner {
        require(shares[_recipient] > 0, "No such beneficiary");
        shares[_recipient] = 0;
        // Remove from array
        for (uint i = 0; i < beneficiaryList.length; i++) {
            if (beneficiaryList[i] == _recipient) {
                beneficiaryList[i] = beneficiaryList[beneficiaryList.length - 1];
                beneficiaryList.pop();
                break;
            }
        }
        emit BeneficiaryRemoved(_recipient);
    }

    function resetAllBeneficiaries() external onlyOwner {
        for (uint i = 0; i < beneficiaryList.length; i++) {
            shares[beneficiaryList[i]] = 0;
        }
        delete beneficiaryList;
        emit BeneficiariesReset();
    }

    function getAllBeneficiaries() external view returns (address[] memory) {
        return beneficiaryList;
    }

    receive() external payable {}
}
