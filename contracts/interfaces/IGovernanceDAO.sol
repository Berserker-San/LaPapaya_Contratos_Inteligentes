// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGovernanceDAO {
    function isProposalApproved(uint256 proposalId) external view returns (bool);
    function getProposal(uint256 proposalId) external view returns (
        uint256 id,
        uint8   proposalType,
        string memory description,
        address proposer,
        uint256 votingDeadline,
        uint256 votesFor,
        uint256 votesAgainst,
        uint8   status,
        bool    finalized
    );
}
