// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {WowTPoints, AccessControlUpgradeable, PausableUpgradeable} from "./WowTPoints.sol";

contract WowTCommunity is AccessControlUpgradeable, PausableUpgradeable {
    address public pointsContract;
    string[] private communities;
    WowTPoints private points;

    struct CommunityDetails {
        string description;
        string imageUrl;
        mapping(address => bool) members;
        // mapping(address => string) userName;
        // string[] quizesforEntry;
        uint256 totalMembers;
        bool exists;
    }

    struct MemberInfo {
        uint256 totalAttendance;
        string[] correctQuizzes;
        bool isQualified;
    }

    mapping(string => uint256) public quizCount;
    mapping(address => mapping(string => MemberInfo)) public eligibilityInfo;
    mapping(string => bool) public defaultCommunity;
    mapping(string => CommunityDetails) public communityMap;
    mapping(address => string) private userName;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Admin role for authorization

    event memberAdded(string communityName, string catagory, address user);

    /// @dev Modifier to restrict function access to only those with the admin role.
    modifier adminOnly() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Must have admin role");
        _;
    }

    function initialize(address _pointsContract) external initializer {
        __Pausable_init();
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        pointsContract = _pointsContract;
        points = WowTPoints(pointsContract);
    }

    function createCommunity(
        string calldata _communityName,
        string calldata _description,
        string calldata _imageUrl
    ) external adminOnly whenNotPaused {
        // Check if community exists
        require(
            !communityMap[_communityName].exists,
            "Community is already created"
        );
        communities.push(_communityName);
        communityMap[_communityName].description = _description;
        communityMap[_communityName].exists = true;
        communityMap[_communityName].imageUrl = _imageUrl;
    }

    function createDefaultCommunity(
        string calldata _communityName,
        string calldata _description,
        string calldata _imageUrl
    ) external adminOnly whenNotPaused {
        // Check if community exists
        require(
            !communityMap[_communityName].exists,
            "Community is already created"
        );
        communities.push(_communityName);
        defaultCommunity[_communityName] = true;
        communityMap[_communityName].description = _description;
        communityMap[_communityName].exists = true;
        communityMap[_communityName].imageUrl = _imageUrl;
    }

    function addMembers(
        string calldata _communityName,
        address _communityParticipant,
        string calldata _userName
    ) external whenNotPaused {
        // Check if community exists
        require(communityMap[_communityName].exists, "Community doesn't exist");

        // Check if user is already part of community
        require(
            !communityMap[_communityName].members[_communityParticipant],
            "Already a member of community"
        );
        require(
            quizCount[_communityName] ==
                eligibilityInfo[_msgSender()][_communityName].totalAttendance,
            "You need to attend all quizes"
        );
        // Check if user has sufficient points to join groups
        if (!(defaultCommunity[_communityName])) {
            require(
                eligibilityInfo[_msgSender()][_communityName].isQualified,
                "You can not join this community"
            );
            require(
                points.getPoints(_communityParticipant) >=
                    points.getPointsValue("communityJoin"),
                "Insufficient points"
            );
            points.reducePoints(_communityParticipant, "communityJoin");
        }

        // Update the userName mapping if the user name is not already available
        if (bytes(userName[_communityParticipant]).length == 0) {
            userName[_communityParticipant] = _userName;
        }

        communityMap[_communityName].members[_communityParticipant] = true;
        communityMap[_communityName].totalMembers += 1;

        emit memberAdded(_communityName, "addMember", _communityParticipant);
    }

    function adminAddMembers(
        string calldata _communityName,
        address _communityParticipant,
        string calldata _userName
    ) external adminOnly whenNotPaused {
        // Check if community exists
        require(communityMap[_communityName].exists, "Community doesn't exist");

        // Check if user is already part of community
        require(
            !communityMap[_communityName].members[_communityParticipant],
            "Already a member of community"
        );

        // Update the userName mapping if the user name is not already available
        if (bytes(userName[_communityParticipant]).length == 0) {
            userName[_communityParticipant] = _userName;
        }

        communityMap[_communityName].members[_communityParticipant] = true;
        communityMap[_communityName].totalMembers += 1;

        emit memberAdded(_communityName, "addMember", _communityParticipant);
    }

    function pause() public adminOnly {
        _pause();
    }

    function unpause() public adminOnly {
        _unpause();
    }

    function setPointsContract(
        address _pointsContract
    ) external adminOnly whenNotPaused {
        pointsContract = _pointsContract;
        points = WowTPoints(pointsContract);
    }

    function setQuizCount(
        string memory _communityName,
        uint256 _count
    ) external adminOnly whenNotPaused {
        quizCount[_communityName] = _count;
    }

    function updateCorrectQuizzes(
        address _userAddress,
        string memory _communityName,
        string memory _quizName
    ) external adminOnly whenNotPaused {
        eligibilityInfo[_userAddress][_communityName].correctQuizzes.push(
            _quizName
        );
    }

    function updateTotalAttendance(
        address _userAddress,
        string memory _communityName,
        uint256 _count
    ) external adminOnly whenNotPaused {
        eligibilityInfo[_userAddress][_communityName].totalAttendance = _count;
    }

    function updateQualifyStatus(
        address _userAddress,
        string memory _communityName,
        bool _status
    ) external adminOnly whenNotPaused {
        eligibilityInfo[_userAddress][_communityName].isQualified = _status;
    }

    function getEligiblityInfo(
        address _userAddress,
        string memory _communityName
    ) public view returns (bool) {
        return eligibilityInfo[_userAddress][_communityName].isQualified;
    }

    function getTotalAttendance(
        address _userAddress,
        string memory _communityName
    ) public view returns (uint256) {
        return eligibilityInfo[_userAddress][_communityName].totalAttendance;
    }

    function getCorrectQuizzes(
        address _userAddress,
        string memory _communityName
    ) public view returns (string[] memory) {
        return eligibilityInfo[_userAddress][_communityName].correctQuizzes;
    }

    function getCommunityDetails(
        string calldata _communityName
    ) public view returns (string memory, string memory, uint256) {
        return (
            communityMap[_communityName].description,
            communityMap[_communityName].imageUrl,
            // communityMap[_communityName].quizesforEntry,
            communityMap[_communityName].totalMembers
        );
    }

    // function updateCommunityQuizes(
    //   string calldata _communityName,
    //   string calldata _quizName
    // ) public adminOnly whenNotPaused {
    //   communityMap[_communityName].quizesforEntry.push(_quizName);
    // }

    function checkMembership(
        string calldata _communityName,
        address _communityParticipant
    ) public view returns (bool) {
        return communityMap[_communityName].members[_communityParticipant];
    }

    // Function to get the user name for a given address
    function getUserName(
        address _userAddress
    ) public view returns (string memory) {
        return userName[_userAddress];
    }

    // function checkQuizesforCommunity(
    //   string calldata _communityName
    // ) public view returns (string[] memory quizesforCommunity) {
    //   return communityMap[_communityName].quizesforEntry;
    // }

    function getCommunities()
        public
        view
        returns (string[] memory, string[] memory, uint256[] memory)
    {
        string[] memory communityNames = new string[](communities.length);
        string[] memory imageUrls = new string[](communities.length);
        uint256[] memory totalMembers = new uint256[](communities.length);

        for (uint256 i = 0; i < communities.length; i++) {
            communityNames[i] = communities[i];
            imageUrls[i] = communityMap[communities[i]].imageUrl;
            totalMembers[i] = communityMap[communities[i]].totalMembers;
        }

        return (communityNames, imageUrls, totalMembers);
    }

    function checkCommunityExists(
        string calldata _communityName
    ) public view returns (bool) {
        return communityMap[_communityName].exists;
    }
}
