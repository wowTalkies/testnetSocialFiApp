// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {WowTCommunity} from "./WowTCommunity.sol";
import {WowTPoints, AccessControlUpgradeable, PausableUpgradeable} from "./WowTPoints.sol";

contract WowTCommunityPoll is AccessControlUpgradeable, PausableUpgradeable {
    struct Poll {
        uint256 id;
        string question;
        string[] options; // Store the options for the poll
        //  mapping(string => uint256) optionToIndex;  // Mapping of option to index
        mapping(string => uint256) votes; // Mapping of option index to vote count
        mapping(address => bool) hasVoted;
        mapping(address => bool) preference;
        uint256 upVotes;
        uint256 downVotes;
        uint256 comments;
        // uint256 optionCount;  // Number of options for the poll
        // mapping(string => uint256) votes; // Mapping of option index to vote count
        // mapping(address => bool) hasVoted;
        address creator;
        string userName;
        uint256 timestamp;
    }

    struct CommunityDetails {
        string name;
        mapping(uint256 => Poll) polls;
        // uint256 pollCount;
    }

    uint256 public pollCount;
    address public communityContract;
    WowTCommunity private community;
    address public pointsContract;
    WowTPoints private points;

    mapping(string => CommunityDetails) public communityDetails;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Admin role for authorization

    /// @dev Modifier to restrict function access to only those with the admin role.
    modifier adminOnly() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Must have poll admin role");
        _;
    }

    event pollCreated(string communityName, string catagory, uint256 pollId);
    event pollVoted(string communityName, string catagory, uint256 pollId);
    event pollUpVoted(
        string communityName,
        string catagory,
        uint256 pollId,
        uint256 upVotes
    );
    event pollDownVoted(
        string communityName,
        string catagory,
        uint256 pollId,
        uint256 downVotes
    );
    event pollCommented(
        string communityName,
        string catagory,
        uint256 pollId,
        uint256 downVotes
    );

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

    function createPoll(
        string calldata _communityName,
        string calldata _question,
        string[] memory _options
    ) public adminOnly whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        // require(
        //   community.checkMembership(_communityName, _msgSender()),
        //   'You are not member in this community'
        // );
        require(bytes(_question).length > 0, "Invalid question");
        string memory userName = community.getUserName(_msgSender());
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        uint256 pollId = pollCount;
        Poll storage newPoll = communityDetail.polls[pollId];
        newPoll.question = _question;
        newPoll.options = _options;
        newPoll.creator = _msgSender();
        newPoll.userName = userName;
        newPoll.timestamp = block.timestamp;
        // for (uint256 i = 0; i < _options.length; i++) {
        //     newPoll.optionToIndex[_options[i]] = i;
        // }
        pollCount++;
        emit pollCreated(_communityName, "poll", pollId);

        // newPoll.yesVotes = 0;
        // newPoll.noVotes = 0;
        // community.polls[pollId] = Poll({
        //     question: _question,
        //     yesVotes: 0,
        //     noVotes: 0
        // });
    }

    function vote(
        string calldata _communityName,
        uint256 _pollId,
        uint256 _optionIndex
    ) public whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_pollId < pollCount, "Invalid poll ID");
        Poll storage poll = communityDetail.polls[_pollId];
        require(poll.creator != _msgSender(), "Cannot vote own poll");
        require(_optionIndex < poll.options.length, "Invalid option index");
        require(!poll.hasVoted[_msgSender()], "Already voted");
        // Get the corresponding option from the provided index
        string memory selectedOption = poll.options[_optionIndex];
        // Increment the vote count for the selected option
        poll.votes[selectedOption]++;
        poll.hasVoted[_msgSender()] = true;
        points.addPoints(_msgSender(), "poll");
        emit pollVoted(_communityName, "poll", _pollId);
    }

    function UpVotePoll(
        string calldata _communityName,
        uint256 _pollId
    ) public whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = communityDetail.polls[_pollId];
        require(poll.creator != _msgSender(), "Cannot upvote own poll");
        require(!(poll.preference[_msgSender()]), "Already interacted");
        poll.upVotes++;
        poll.preference[_msgSender()] = true;
        points.addPoints(_msgSender(), "upVote");
        emit pollUpVoted(_communityName, "poll", _pollId, poll.upVotes);
    }

    function downVotePoll(
        string calldata _communityName,
        uint256 _pollId
    ) public whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = communityDetail.polls[_pollId];
        require(poll.creator != _msgSender(), "Cannot downvote own poll");
        require(!(poll.preference[_msgSender()]), "Already interacted");
        poll.downVotes++;
        poll.preference[_msgSender()] = true;
        points.addPoints(_msgSender(), "downVote");
        emit pollDownVoted(_communityName, "poll", _pollId, poll.downVotes);
    }

    function commentPoll(
        string calldata _communityName,
        uint256 _pollId
    ) public whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = communityDetail.polls[_pollId];
        poll.comments++;
        points.addPoints(_msgSender(), "comment");
        emit pollCommented(_communityName, "poll", _pollId, poll.comments);
    }

    function pause() public adminOnly {
        _pause();
    }

    function unpause() public adminOnly {
        _unpause();
    }

    function getPollCount() public view returns (uint256) {
        return pollCount;
    }

    function getPoll(
        string calldata _communityName,
        uint256 _pollId
    )
        public
        view
        returns (
            string memory,
            string[] memory,
            uint256,
            uint256,
            uint256[] memory,
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
        require(_pollId < pollCount, "Invalid poll ID");
        Poll storage poll = communityDetail.polls[_pollId];
        uint256[] memory voteCounts = new uint256[](poll.options.length);
        for (uint256 i = 0; i < poll.options.length; i++) {
            voteCounts[i] = poll.votes[poll.options[i]];
        }
        return (
            poll.question,
            poll.options,
            poll.upVotes,
            poll.downVotes,
            voteCounts,
            poll.timestamp,
            poll.creator,
            poll.userName
        );
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

    function setPollUserName(
        string calldata _communityName,
        uint256 _pollId,
        string calldata _userName
    ) external adminOnly whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = communityDetail.polls[_pollId];
        poll.userName = _userName;
    }

    function setPollOptions(
        string calldata _communityName,
        uint256 _pollId,
        string[] calldata _newOptions
    ) external adminOnly whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = communityDetail.polls[_pollId];
        require(
            poll.creator == _msgSender(),
            "Only the poll creator can set new options"
        );
        require(_newOptions.length > 0, "New options must not be empty");

        // Clear the existing options and votes
        for (uint256 i = 0; i < poll.options.length; i++) {
            delete poll.votes[poll.options[i]];
        }

        // Set the new options
        poll.options = new string[](_newOptions.length);
        for (uint256 i = 0; i < _newOptions.length; i++) {
            poll.options[i] = _newOptions[i];
        }

        // Reset other poll properties
        poll.upVotes = 0;
        poll.downVotes = 0;
        poll.comments = 0;
        poll.hasVoted[_msgSender()] = false;

        emit pollCreated(_communityName, "poll", _pollId);
    }
}
