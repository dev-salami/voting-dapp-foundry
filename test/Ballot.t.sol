// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import "forge-std/console.sol";
import {DeployBallot} from "../script/DeployBallot.s.sol";
import {Ballot} from "../src/Ballot.sol";
import {Test, console} from "forge-std/Test.sol";

contract BallotTest is Test {
    Ballot public ballot;
    address public constant USER1 = address(1);
    address public constant USER5 = address(5);

    function setUp() external {
        ballot = new DeployBallot().run();
    }

    function testOnlyChairman_CanGiveRightToVote() public {
        vm.expectRevert();
        ballot.giveRightToVote(USER1);
    }

    modifier GiveRightToVote() {
        vm.startPrank(ballot.ChairPerson());
        ballot.giveRightToVote(USER1);
        vm.stopPrank();
        assert(uint(ballot.VotersDetail(USER1).weight) == 1);
        _;
    }

    modifier Vote() {
        vm.startPrank(ballot.ChairPerson());
        ballot.giveRightToVote(USER1);
        vm.stopPrank();
        vm.startPrank(USER1);
        ballot.vote(1);
        vm.stopPrank();
        _;
    }

    function testVote() public Vote {
        assertEq(ballot.CandidateVoteNumber(1), 1);
    }

    // function testVotingProcess() public Vote {
    //     vm.startPrank(USER1);
    //     console.log(msg.sender);
    //     assertEq(ballot.VotersDetail(USER1).voted, true);
    // }

    function testAlreadyVoted() public Vote {
        vm.expectRevert();
        vm.startPrank(USER1);
        ballot.vote(1);
    }

    function testGiveRightToVote() public GiveRightToVote {
        // console.log(ballot.VotersDetail(USER).weight);
        assertEq((ballot.VotersDetail(USER1).weight), 1);
    }

    // function testAlreadyHaveRightToVote() public GiveRightToVote {
    //     console.log(ballot.VotersDetail(USER1).weight);
    //     console.log(ballot.VotersDetail(USER5).weight);
    //     vm.expectRevert();

    //     vm.Prank(ballot.ChairPerson());
    //     ballot.giveRightToVote(USER1);

    //     // vm.stopPrank();
    // }

    function testBallotWinnerName() public Vote {
        assertEq(ballot.winnerName(), "Atiku");
    }

    function testWinningProposal() public Vote {
        assertEq(ballot.winningProposal(), 1);
    }

    function testNoElection() public {
        assert(ballot.winningProposal() == 0);
        // assertEq(ballot.winningProposal(), 0);
    }

    function testHasNoRightToVote() public Vote {
        // console.log(ballot.VotersDetail(USER).weight);
        vm.expectRevert();
        vm.prank(USER5);
        ballot.vote(1);
    }

    function testCannotSelfDelegate() public GiveRightToVote {
        // console.log(ballot.VotersDetail(USER).weight);
        vm.expectRevert();
        vm.prank(USER1);
        ballot.delegate(USER1);
    }

    function testCannotDelegateVote__NotAccredited() public {
        vm.expectRevert();
        vm.prank(USER1);
        ballot.delegate(USER1);
    }

    function testCannotDelegateVote__AlreadyVoted() public Vote {
        // console.log(ballot.VotersDetail(USER).weight);
        vm.expectRevert();
        vm.prank(USER1);
        ballot.delegate(USER5);
    }

    function testInvalidAddress() public GiveRightToVote {
        vm.expectRevert();
        vm.prank(USER1);
        ballot.delegate(address(0));
        // console.log(ballot.VotersDetail(USER).weight);
    }

    function testCannotDelegateToUnAccreditedVoter() public GiveRightToVote {
        vm.expectRevert();
        vm.prank(USER1);
        ballot.delegate(USER5);
        // console.log(ballot.VotersDetail(USER).weight);
    }
}
