// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title Voting with delegation.
contract Ballot {
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
        address delegate; // person delegated to
        uint vote; // index of the voted proposal
    }

    struct Proposal {
        string name; // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address private immutable i_chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public s_proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor(string[] memory proposalNames) {
        i_chairperson = msg.sender;
        voters[i_chairperson].weight = 1;

        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.
        for (uint i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` creates a temporary
            // Proposal object and `s_proposals.push(...)`
            // appends it to the end of `s_proposals`.
            s_proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    function giveRightToVote(address voter) external {
        require(
            msg.sender == i_chairperson,
            "Only i_chairperson can give right to vote."
        );
        require(!voters[voter].voted, "The voter already voted.");
        require(
            voters[voter].weight == 0,
            "You cannot be given right to vote more than once"
        );
        voters[voter].weight = 1;
    }

    /// Delegate your vote to the voter `to`.
    function delegate(address to) external {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        require(
            sender.weight != 0,
            "Cannot Give out vote because you have no right to vote"
        );
        require(!sender.voted, "You already voted. --Delegate");

        require(to != msg.sender, "Self-delegation is disallowed.");
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }

        Voter storage delegate_ = voters[to];

        // Voters cannot delegate to accounts that cannot vote.
        require(
            delegate_.weight >= 1,
            "Cannot delegate to accounts that cannot vote"
        );

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender]`.
        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            s_proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted. --Vote");
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        s_proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < s_proposals.length; p++) {
            if (s_proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = s_proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the s_proposals array and then
    // returns the name of the winner
    function winnerName() external view returns (string memory winnerName_) {
        winnerName_ = s_proposals[winningProposal()].name;
    }

    function ChairPerson() external view returns (address) {
        return i_chairperson;
    }

    function VotersDetail(
        address me
    ) external view returns (Voter memory detail) {
        return voters[me];
    }

    function CandidateVoteNumber(uint index) external view returns (uint) {
        return s_proposals[index].voteCount;
    }
}
