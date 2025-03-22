// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract InheritanceContract {
    address public owner;
    address public oracle;
    bool public isDeceased = false;
    uint256 public deceasedTime;
    string public encryptedWillHash;

    IERC20 public token;

    struct Beneficiary {
        address recipient;
        uint256 share;
    }

    Beneficiary[] public tokenBeneficiaries;
    mapping(address => uint256) public tokenShares;
    uint256 public totalTokenShares;

    mapping(address => bool) public isVerifier;
    mapping(address => mapping(address => bool)) public approvals;
    mapping(address => uint256) public approvalCount;
    mapping(address => bool) public isVerified;
    uint256 public requiredApprovals = 2;

    event BeneficiaryAdded(address indexed recipient, uint256 share);
    event IdentityApproved(address indexed beneficiary, address verifier);
    event IdentityVerified(address indexed beneficiary);
    event DeathConfirmed(uint256 time);
    event FundsDistributed();
    event WillHashSet(string ipfsHash);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        require(!isDeceased, "Already deceased");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Only oracle can confirm");
        _;
    }

    constructor(address _oracle, address _token) {
        owner = msg.sender;
        oracle = _oracle;
        token = IERC20(_token);
    }

    function addTokenBeneficiary(address _recipient, uint256 _share) external onlyOwner {
        require(_share > 0, "Invalid share");

        if (tokenShares[_recipient] == 0) {
            tokenBeneficiaries.push(Beneficiary(_recipient, _share));
        } else {
            for (uint i = 0; i < tokenBeneficiaries.length; i++) {
                if (tokenBeneficiaries[i].recipient == _recipient) {
                    totalTokenShares -= tokenBeneficiaries[i].share;
                    tokenBeneficiaries[i].share = _share;
                    break;
                }
            }
        }

        tokenShares[_recipient] = _share;
        totalTokenShares += _share;
        emit BeneficiaryAdded(_recipient, _share);
    }

    function approveIdentity(address _beneficiary) external {
        require(isVerifier[msg.sender], "Not authorized verifier");
        require(!approvals[_beneficiary][msg.sender], "Already approved");

        approvals[_beneficiary][msg.sender] = true;
        approvalCount[_beneficiary]++;

        emit IdentityApproved(_beneficiary, msg.sender);

        if (approvalCount[_beneficiary] >= requiredApprovals && !isVerified[_beneficiary]) {
            isVerified[_beneficiary] = true;
            emit IdentityVerified(_beneficiary);
        }
    }

    function confirmDeceased() external onlyOracle {
        require(!isDeceased, "Already confirmed");
        isDeceased = true;
        deceasedTime = block.timestamp;
        emit DeathConfirmed(deceasedTime);
    }

    function setEncryptedWill(string calldata _ipfsHash) external onlyOwner {
        encryptedWillHash = _ipfsHash;
        emit WillHashSet(_ipfsHash);
    }

    function getEncryptedWill() external view returns (string memory) {
        return encryptedWillHash;
    }

    function distributeToken() external {
        require(isDeceased, "Owner not deceased");
        require(totalTokenShares > 0, "No token shares");

        uint256 balance = token.balanceOf(address(this));

        for (uint i = 0; i < tokenBeneficiaries.length; i++) {
            address recipient = tokenBeneficiaries[i].recipient;
            if (isVerified[recipient]) {
                uint256 amount = (balance * tokenBeneficiaries[i].share) / totalTokenShares;
                token.transfer(recipient, amount);
            }
        }

        totalTokenShares = 0;
        emit FundsDistributed();
    }

    function addVerifier(address _verifier) external onlyOwner {
        isVerifier[_verifier] = true;
    }

    function setRequiredApprovals(uint256 _count) external onlyOwner {
        require(_count > 0, "Must be > 0");
        requiredApprovals = _count;
    }

    function getBeneficiaries() external view returns (Beneficiary[] memory) {
        return tokenBeneficiaries;
    }
}
