// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
// import { AccessControlUpgradeable } from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
// import { WowTCommunity } from './WowTCommunity.sol';

// contract WowTCommunityPostV1 is OwnableUpgradeable, AccessControlUpgradeable {
//     struct Post {
//         uint256 id;
//         string content;
//         string imageUrl;
//         uint256 likes;
//         uint256 dislikes;
//         uint256 commands;
//         uint256 timestamp;
//         address creator;
//         string communityName;
//     }

//     struct CommunityDetails {
//         string name;
//         Post[] posts;
//     }

//     address public communityContract;
//     WowTCommunity private community;
//     mapping(string => CommunityDetails) public communityDetails;
//     bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

//     function initialize(address _communityContract) external initializer {
//         __Ownable_init();
//         _grantRole(ADMIN_ROLE, _msgSender());
//         _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
//         communityContract = _communityContract;
//         community = WowTCommunity(communityContract);
//     }

//     function createPost(
//         string calldata _communityName,
//         string calldata _content,
//         string calldata _imageUrl,
//         address creator
//     ) public {
//         require(
//             community.checkCommunityExists(_communityName),
//             "Community doesn't exist"
//         );
//         CommunityDetails storage communityDetail = communityDetails[_communityName];

//         Post memory newPost = Post({
//             id: communityDetail.posts.length,
//             content: _content,
//             imageUrl: _imageUrl,
//             likes: 0,
//             dislikes: 0,
//             commands: 0,
//             timestamp: block.timestamp,
//             creator: creator,
//             communityName: _communityName
//         });

//         communityDetail.posts.push(newPost);
//     }

//     function likePost(string calldata _communityName, uint256 _postId) public {
//         require(
//             community.checkCommunityExists(_communityName),
//             "Community doesn't exist"
//         );
//         CommunityDetails storage communityDetail = communityDetails[_communityName];
//         require(_postId < communityDetail.posts.length, 'Invalid post ID');
//         Post storage post = communityDetail.posts[_postId];
//         post.likes++;
//     }

//     function dislikePost(string calldata _communityName, uint256 _postId) public {
//         require(
//             community.checkCommunityExists(_communityName),
//             "Community doesn't exist"
//         );
//         CommunityDetails storage communityDetail = communityDetails[_communityName];
//         require(_postId < communityDetail.posts.length, 'Invalid post ID');
//         Post storage post = communityDetail.posts[_postId];
//         post.dislikes++;
//     }

//     function commandPost(string calldata _communityName, uint256 _postId) public {
//         require(
//             community.checkCommunityExists(_communityName),
//             "Community doesn't exist"
//         );
//         CommunityDetails storage communityDetail = communityDetails[_communityName];
//         require(_postId < communityDetail.posts.length, 'Invalid post ID');
//         Post storage post = communityDetail.posts[_postId];
//         post.commands++;
//     }

//     function getPostsByCommunityName(string calldata _communityName)
//         public
//         view
//         returns (Post[] memory)
//     {
//         require(
//             community.checkCommunityExists(_communityName),
//             "Community doesn't exist"
//         );
//         CommunityDetails storage communityDetail = communityDetails[_communityName];
//         return communityDetail.posts;
//     }

//     function getPostCount(string calldata _communityName)
//         public
//         view
//         returns (uint256)
//     {
//         require(
//             community.checkCommunityExists(_communityName),
//             "Community doesn't exist"
//         );
//         CommunityDetails storage communityDetail = communityDetails[_communityName];
//         return communityDetail.posts.length;
//     }
// }
