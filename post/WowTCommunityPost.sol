// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {WowTCommunity} from "./WowTCommunity.sol";
import {WowTPoints, AccessControlUpgradeable, PausableUpgradeable} from "./WowTPoints.sol";

contract WowTCommunityPost is AccessControlUpgradeable, PausableUpgradeable {
    struct Post {
        uint256 id;
        string content;
        string imageUrl;
        uint256 upVotes;
        uint256 downVotes;
        uint256 comments;
        mapping(address => bool) preference;
        uint256 timestamp;
        string userName;
        address creator;
        string communityName;
    }

    struct CommunityDetails {
        string name;
        // uint256[] postIds;
        mapping(uint256 => Post) posts;
        // uint256 postCount;
    }

    uint256 public postCount;
    address public communityContract;
    WowTCommunity private community;
    address public pointsContract;
    WowTPoints private points;

    // mapping(string => mapping(uint256 => Post)) public posts;
    //   mapping(address => uint256[]) public userPosts; // user address => post IDs
    mapping(string => CommunityDetails) public communityDetails;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Admin role for authorization

    event postCreated(string communityName, string catagory, uint256 postId);
    event postUpVoted(
        string communityName,
        string catagory,
        uint256 postId,
        uint256 upVotes
    );
    event postDownVoted(
        string communityName,
        string catagory,
        uint256 postId,
        uint256 downVotes
    );
    event postCommented(
        string communityName,
        string catagory,
        uint256 postId,
        uint256 commentVotes
    );

    /// @dev Modifier to restrict function access to only those with the admin role.
    modifier adminOnly() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Must have post admin role");
        _;
    }

    // uint256 public postCount;

    function initialize(
        address _pointsContract,
        address _communityContract
    ) external initializer {
        // __Ownable_init();
        __Pausable_init();
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        communityContract = _communityContract;
        community = WowTCommunity(communityContract);
        pointsContract = _pointsContract;
        points = WowTPoints(_pointsContract);
    }

    function createPost(
        string calldata _communityName,
        string calldata _content,
        string calldata _imageUrl
    ) public whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        require(
            community.checkMembership(_communityName, _msgSender()),
            "You are not member in this community"
        );
        string memory userName = community.getUserName(_msgSender());
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        Post storage newPost = communityDetail.posts[postCount];
        newPost.id = postCount;
        newPost.content = _content;
        newPost.imageUrl = _imageUrl;
        newPost.userName = userName;
        newPost.creator = _msgSender();
        newPost.communityName = _communityName;
        newPost.timestamp = block.timestamp;
        postCount++;
        points.addPoints(_msgSender(), "post");
        emit postCreated(_communityName, "post", newPost.id);
        // userPosts[msg.sender].push(community.postCount); // Add post ID to userPosts mapping
    }

    function UpVotePost(
        string calldata _communityName,
        uint256 _postId
    ) public whenNotPaused {
        // require(_postId > 0 && _postId <= postCount, "Invalid post ID");
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_postId <= postCount, "Invalid post ID");
        Post storage post = communityDetail.posts[_postId];
        // Check if the caller is the post creator
        require(post.creator != _msgSender(), "Cannot upvote own post");
        require(!(post.preference[_msgSender()]), "Already interacted");
        post.upVotes++;
        post.preference[_msgSender()] = true;
        points.addPoints(_msgSender(), "upVote");
        emit postUpVoted(_communityName, "post", _postId, post.upVotes);
    }

    function downVotePost(
        string calldata _communityName,
        uint256 _postId
    ) public whenNotPaused {
        //require(_postId > 0 && _postId <= postCount, "Invalid post ID");
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_postId <= postCount, "Invalid post ID");
        Post storage post = communityDetail.posts[_postId];
        // Check if the caller is the post creator
        require(post.creator != _msgSender(), "Cannot downvote own post");
        require(!(post.preference[_msgSender()]), "Already interacted");
        post.downVotes++;
        post.preference[_msgSender()] = true;
        points.addPoints(_msgSender(), "downVote");
        emit postDownVoted(_communityName, "post", _postId, post.downVotes);
    }

    function commentPost(
        string calldata _communityName,
        uint256 _postId
    ) public whenNotPaused {
        // require(_postId > 0 && _postId <= postCount, "Invalid post ID");
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_postId <= postCount, "Invalid post ID");
        Post storage post = communityDetail.posts[_postId];
        post.comments++;
        points.addPoints(_msgSender(), "comment");
        emit postCommented(_communityName, "post", _postId, post.comments);
    }

    // function tipPost(
    //   string calldata _communityName,
    //   uint256 _postId,
    //   uint256 _points
    // ) public whenNotPaused {
    //   require(
    //     community.checkCommunityExists(_communityName),
    //     "Community doesn't exist"
    //   );
    //   CommunityDetails storage communityDetail = communityDetails[_communityName];
    //   require(_postId <= postCount, 'Invalid post ID');
    //   Post storage post = communityDetail.posts[_postId];
    //   // Ensure the caller is not the post creator
    //   require(post.creator != _msgSender(), 'Cannot tip your own post');
    //   points.addPoints(post.creator, _points, 'tip-post');
    //   points.reducePoints(_msgSender(), _points, 'tip');
    // }

    function pause() public adminOnly {
        _pause();
    }

    function unpause() public adminOnly {
        _unpause();
    }

    function getPost(
        string calldata _communityName,
        uint256 _postId
    )
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            string memory
        )
    {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_postId < postCount, "Invalid post ID");
        Post storage post = communityDetail.posts[_postId];
        return (
            post.content,
            post.imageUrl,
            post.upVotes,
            post.downVotes,
            post.comments,
            post.timestamp,
            post.creator,
            post.userName
        );
    }

    function getPostCount() public view returns (uint256) {
        return postCount;
    }

    function setCommunityContractAddress(
        address _communityContract
    ) external adminOnly whenNotPaused {
        communityContract = _communityContract;
        community = WowTCommunity(_communityContract);
    }

    function setPointsContractAddress(
        address _pointsContract
    ) external adminOnly whenNotPaused {
        pointsContract = _pointsContract;
        points = WowTPoints(_pointsContract);
    }

    // development

    // function setPostName(
    //   string calldata _communityName,
    //   uint256 _postId,
    //   string memory _userName
    // ) external onlyOwner {
    //   require(
    //     community.checkCommunityExists(_communityName),
    //     "Community doesn't exist"
    //   );
    //   CommunityDetails storage communityDetail = communityDetails[_communityName];
    //   require(_postId <= postCount, 'Invalid post ID');
    //   Post storage post = communityDetail.posts[_postId];
    //   post.userName = _userName;
    // }

    // function getCommunityPosts(string memory _communityName, uint256 _postId) public view
    // returns (uint256, string memory, uint256, uint256, uint256) {
    //     require(_postId > 0 && _postId <= postCount, "Invalid post ID");

    //     Post storage post = posts[_communityName][_postId];
    //     return (post.id, post.content, post.likes, post.dislikes, post.commands);
    // }

    // function getUserPosts(address _userAddress) public view returns (uint256[] memory) {
    //     return userPosts[_userAddress];
    // }

    // function getCommunityPosts(
    //   string memory _communityName
    // ) public view returns (Post[] memory) {
    //   // require(_communityId > 0 && _communityId <= communityCount, "Invalid community ID");
    //   CommunityDetails storage communityDetails = communities[_communityName];

    //   Post[] memory communityPosts = new Post[](communityDetails.postCount);
    //   for (uint256 i = 0; i < communityDetails.postCount; i++) {
    //     communityPosts[i] = communityDetails.posts[i + 1];
    //   }

    //   return communityPosts;
    // }

    // function getUserPosts(address _userAddress) public view returns (Post[] memory) {
    //     uint256[] storage postIds = userPosts[_userAddress];
    //     Post[] memory userPostsArray = new Post[](postIds.length);

    //     for (uint256 i = 0; i < postIds.length; i++) {
    //         uint256 postId = postIds[i];
    //         for (uint256 j = 1; j <= communityCount; j++) {
    //             Community storage community = communities[j];
    //             if (postId <= community.postCount) {
    //                 userPostsArray[i] = community.posts[postId];
    //                 break;
    //             }
    //         }
    //     }

    //     return userPostsArray;
    // }
}
