// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
// import { AccessControlUpgradeable } from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
// import { WowTCommunity } from './WowTCommunity.sol';

// contract WowTCommunityPollV1 is OwnableUpgradeable, AccessControlUpgradeable {
//     struct Poll {
//         string question;
//         string[] options;
//         uint256[] votes;
//         // mapping(address => bool) hasVoted;
//         uint256 timestamp;
//     }

//     struct CommunityDetails {
//         string name;
//         Poll[] polls;
//     }

//     address public communityContract;
//     WowTCommunity private community;

//     mapping(string => CommunityDetails) public communityDetails;
//     mapping(address => mapping(uint256 => bool)) public hasVoted;

//     bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE'); // Admin role for authorization

//     function initialize(address _communityContract) external initializer {
//         __Ownable_init();
//         _grantRole(ADMIN_ROLE, _msgSender());
//         _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
//         communityContract = _communityContract;
//         community = WowTCommunity(communityContract);
//     }

//     function createPoll(
//         string calldata _communityName,
//         string calldata _question,
//         string[] memory _options
//     ) public {
//         require(community.checkCommunityExists(_communityName), "Community doesn't exist");
//         require(bytes(_question).length > 0, "Invalid question");
//         CommunityDetails storage communityDetail = communityDetails[_communityName];
//         Poll storage newPoll = communityDetail.polls[communityDetail.polls.length];
//         newPoll.question = _question;
//         newPoll.options = _options;
//         newPoll.votes = new uint256[](_options.length);
//         newPoll.timestamp = block.timestamp;

//         communityDetail.polls.push(newPoll);
//     }

//     function vote(
//         string calldata _communityName,
//         uint256 _pollId,
//         uint256 _optionIndex,
//         address _user
//     ) public {
//         require(community.checkCommunityExists(_communityName), "Community doesn't exist");
//         CommunityDetails storage communityDetail = communityDetails[_communityName];
//         require(_pollId < communityDetail.polls.length, "Invalid poll ID");
//         Poll storage poll = communityDetail.polls[_pollId];
//         require(_optionIndex < poll.options.length, "Invalid option index");
//         require(!hasVoted[_user][_pollId], "Already voted");

//         poll.votes[_optionIndex]++;
//         hasVoted[_user][_pollId] = true;
//     }

//     function getPollCount(string calldata _communityName) public view returns (uint256) {
//         require(community.checkCommunityExists(_communityName), "Community doesn't exist");
//         return communityDetails[_communityName].polls.length;
//     }

//     function getPoll(
//         string calldata _communityName,
//         uint256 _pollId
//     )
//         public
//         view
//         returns (
//             string memory,
//             string[] memory,
//             uint256[] memory,
//             uint256
//         )
//     {
//         require(community.checkCommunityExists(_communityName), "Community doesn't exist");
//         CommunityDetails storage communityDetail = communityDetails[_communityName];
//         require(_pollId < communityDetail.polls.length, "Invalid poll ID");
//         Poll storage poll = communityDetail.polls[_pollId];
//         return (poll.question, poll.options, poll.votes, poll.timestamp);
//     }

//     function getPollsByCommunityName(string calldata _communityName)
//         public
//         view
//         returns (Poll[] memory)
//     {
//         require(community.checkCommunityExists(_communityName), "Community doesn't exist");
//         return communityDetails[_communityName].polls;
//     }
// }
