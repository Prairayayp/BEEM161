// Enhanced Inheritance DApp Frontend with Verifier Approval & IPFS Upload (CID optional)
import React, { useState } from "react";
import { ethers } from "ethers";

const CONTRACT_ADDRESS = "0x6ed6408147489500C5cC4a50DB1EBcad710450BE";
const ABI = [
  "function setEncryptedWill(string _ipfsHash) external",
  "function getEncryptedWill() view returns (string)",
  "function addTokenBeneficiary(address _recipient, uint256 _share) external",
  "function approveIdentity(address _beneficiary) external",
  "function confirmDeceased() external",
  "function distributeToken() external"
];

function InheritanceDApp() {
  const [account, setAccount] = useState("");
  const [ipfsHash, setIpfsHash] = useState("");
  const [newHash, setNewHash] = useState("");
  const [recipient, setRecipient] = useState("");
  const [share, setShare] = useState("");
  const [verifyTarget, setVerifyTarget] = useState("");
  const [ipfsFile, setIpfsFile] = useState(null);

  const connectWallet = async () => {
    if (window.ethereum) {
      const [selectedAccount] = await window.ethereum.request({ method: "eth_requestAccounts" });
      setAccount(selectedAccount);
    }
  };

  const getContract = () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = provider.getSigner();
    return new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
  };

  const uploadIPFSHash = async () => {
    const contract = getContract();
    const tx = await contract.setEncryptedWill(newHash);
    await tx.wait();
    alert("Encrypted will hash saved on-chain!");
  };

  const fetchEncryptedWill = async () => {
    const contract = getContract();
    const hash = await contract.getEncryptedWill();
    setIpfsHash(hash);
  };

  const addBeneficiary = async () => {
    const contract = getContract();
    const tx = await contract.addTokenBeneficiary(recipient, ethers.parseUnits(share, 0));
    await tx.wait();
    alert("Beneficiary added!");
  };

  const approveIdentity = async () => {
    const contract = getContract();
    const tx = await contract.approveIdentity(verifyTarget);
    await tx.wait();
    alert("Identity approved by verifier!");
  };

  const uploadToIPFS = async () => {
    if (!ipfsFile) return alert("Select a file first");
    const form = new FormData();
    form.append("file", ipfsFile);

    const res = await fetch("https://ipfs.infura.io:5001/api/v0/add", {
      method: "POST",
      body: form
    });

    const text = await res.text();
    const cidMatch = text.match(/Qm[\w\d]+/);
    if (cidMatch) {
      const cid = cidMatch[0];
      setNewHash(cid);
      alert("Uploaded to IPFS: " + cid);
    } else {
      alert("IPFS upload failed");
    }
  };

  return (
    <div style={{ padding: "2rem", maxWidth: "700px", margin: "auto" }}>
      <h2>Connect Wallet</h2>
      <button onClick={connectWallet}>{account || "Connect MetaMask"}</button>

      <h2 style={{ marginTop: "2rem" }}>Upload Encrypted Will (IPFS)</h2>
      <input type="file" onChange={(e) => setIpfsFile(e.target.files[0])} />
      <button onClick={uploadToIPFS}>Upload File to IPFS</button>

      <h2>Or enter existing IPFS hash</h2>
      <input value={newHash} onChange={(e) => setNewHash(e.target.value)} placeholder="Qm..." />
      <button onClick={uploadIPFSHash}>Store Hash on Blockchain</button>
      <button onClick={fetchEncryptedWill}>View Current On-Chain Hash</button>
      {ipfsHash && <p>Stored: {ipfsHash}</p>}

      <h2 style={{ marginTop: "2rem" }}>Add ERC20 Beneficiary</h2>
      <input value={recipient} onChange={(e) => setRecipient(e.target.value)} placeholder="0xRecipientAddress" />
      <input value={share} onChange={(e) => setShare(e.target.value)} placeholder="Share (e.g. 50)" />
      <button onClick={addBeneficiary}>Add Beneficiary</button>

      <h2 style={{ marginTop: "2rem" }}>Verifier Identity Approval</h2>
      <input value={verifyTarget} onChange={(e) => setVerifyTarget(e.target.value)} placeholder="0xBeneficiaryAddress" />
      <button onClick={approveIdentity}>Approve Identity</button>
    </div>
  );
}

export default InheritanceDApp;
