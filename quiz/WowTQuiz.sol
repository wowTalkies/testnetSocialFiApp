// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;
// import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { WowTCommunity } from './WowTCommunity.sol';
import { WowTPoints, AccessControlUpgradeable, PausableUpgradeable } from './WowTPoints.sol';

//import "hardhat/console.sol";
contract WowTQuiz is PausableUpgradeable, AccessControlUpgradeable {
  //Points conracts
  address public pointsContract;
  WowTPoints private points;
  address public communityContract;
  WowTCommunity private community;

  //Quiz structure
  struct Quiz {
    string description;
    string imageUrl;
    string question;
    string[4] options;
    bytes32 answer;
    address creatorAddress;
  }

  mapping(string => string[]) public entryLevelQuizNames;
  mapping(string => string[]) public quizNames;
  mapping(string => Quiz) public quizmap;
  mapping(string => mapping(address => bool)) public evalStatus;

  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE'); // Admin role for authorization

  /// @dev Modifier to restrict function access to only those with the admin role.
  modifier adminOnly() {
    require(hasRole(ADMIN_ROLE, _msgSender()), 'Must have quiz admin role');
    _;
  }

  event QuizCreated(string communityName, string category, string quizName);
  event QuizEvaluated(string communityName, string category, string quizName);

  // for checking answer
  event Answer(bool indexed);

  function initialize(
    address _pointsContract,
    address _communityContract
  ) external initializer {
    pointsContract = _pointsContract;
    points = WowTPoints(_pointsContract);
    communityContract = _communityContract;
    community = WowTCommunity(_communityContract);
    __Pausable_init();
    _grantRole(ADMIN_ROLE, _msgSender());
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  // Create Entry Quiz
  function createEntryQuiz(
    string memory _communityName,
    string memory _quizName,
    // Question memory _question,
    string memory _description,
    string memory _imageUrl,
    string memory _question,
    string[4] memory _options,
    bytes32 _answer
  ) external adminOnly whenNotPaused {
    require(
      community.checkCommunityExists(_communityName),
      "Community doesn't exist"
    );
    entryLevelQuizNames[_communityName].push(_quizName);
    // community.updateCommunityQuizes(_communityName, _quizName);

    quizmap[_quizName] = Quiz({
      description: _description,
      imageUrl: _imageUrl,
      question: _question,
      options: _options,
      answer: _answer,
      creatorAddress: _msgSender()
    });
    uint256 communityQuizCount = community.quizCount(_communityName) + 1;
    community.setQuizCount(_communityName, communityQuizCount);
    emit QuizCreated(_communityName, 'quiz', _quizName);
  }

  // Create Quiz
  function createQuiz(
    string memory _communityName,
    string memory _quizName,
    // Question memory _question,
    string memory _description,
    string memory _imageUrl,
    string memory _question,
    string[4] memory _options,
    bytes32 _answer,
    address _userAddress
  ) external adminOnly whenNotPaused {
    uint256 userPoints = points.getPoints(_userAddress);
    require(
      userPoints >= points.getPointsValue('createQuiz') ||
        hasRole(ADMIN_ROLE, _userAddress),
      'Not enough point to create Quiz'
    );
    require(
      community.checkCommunityExists(_communityName),
      "Community doesn't exist"
    );
    require(
      community.checkMembership(_communityName, _userAddress),
      'You are not member in this community'
    );
    quizNames[_communityName].push(_quizName);
    // community.updateCommunityQuizes(_communityName, _quizName);

    quizmap[_quizName] = Quiz({
      description: _description,
      imageUrl: _imageUrl,
      question: _question,
      options: _options,
      answer: _answer,
      creatorAddress: _userAddress
    });
    points.reducePoints(_userAddress, 'createQuiz');
    emit QuizCreated(_communityName, 'quiz', _quizName);
  }

  function quizEval(
    string memory _communityName,
    string memory _quizName,
    bytes32 choice,
    address _userAddress
  ) external adminOnly whenNotPaused {
    require(!evalStatus[_quizName][_userAddress], 'Already tried');
    Quiz memory qtemp = getQuizdetails(_quizName);
    require(_userAddress != qtemp.creatorAddress, "Can't attend your own quiz");

    bool isCorrect = (qtemp.answer == choice);
    if (isCorrect) {
      community.updateCorrectQuizzes(_userAddress, _communityName, _quizName);
      points.addPoints(_userAddress, 'answerQuiz');

      // Check if the user has answered all quizzes correctly
      uint256 correctQuizzes = community
        .getCorrectQuizzes(_userAddress, _communityName)
        .length;
      if (correctQuizzes == community.quizCount(_communityName)) {
        community.updateQualifyStatus(_userAddress, _communityName, true);
      }
    }
    // Add points to the creator only for non-entry level quizzes
    if (!isEntryLevelQuiz(_communityName, _quizName)) {
      points.addPoints(qtemp.creatorAddress, 'quizCreator');
    }
    evalStatus[_quizName][_userAddress] = true;
    uint256 totalAttendance = community.getTotalAttendance(
      _userAddress,
      _communityName
    ) + 1;
    community.updateTotalAttendance(
      _userAddress,
      _communityName,
      totalAttendance
    );
    emit Answer(isCorrect);
    emit QuizEvaluated(_communityName, 'quiz', _quizName);
  }

  function changeQuizName(
    string memory _communityName,
    string memory _currentQuizName,
    string memory _newQuizName
  ) external adminOnly whenNotPaused {
    require(
      quizmap[_currentQuizName].creatorAddress != address(0),
      "Quiz doesn't exist"
    );
    require(
      !quizNameExists(_communityName, _newQuizName),
      'New quiz name already exists'
    );

    // Update the quiz name in the mapping
    quizmap[_newQuizName] = quizmap[_currentQuizName];
    delete quizmap[_currentQuizName];

    // Update the quiz name in the quizNames mapping
    string[] storage quizList = quizNames[_communityName];
    for (uint256 i = 0; i < quizList.length; i++) {
      if (keccak256(bytes(quizList[i])) == keccak256(bytes(_currentQuizName))) {
        quizList[i] = _newQuizName;
        break;
      }
    }

    // Update the entryLevelQuizNames mapping if necessary
    string[] storage entryQuizList = entryLevelQuizNames[_communityName];
    for (uint256 i = 0; i < entryQuizList.length; i++) {
      if (
        keccak256(bytes(entryQuizList[i])) == keccak256(bytes(_currentQuizName))
      ) {
        entryQuizList[i] = _newQuizName;
        break;
      }
    }

    emit QuizCreated(_communityName, 'quiz', _newQuizName);
  }

  function deleteQuiz(
    string memory _communityName,
    string memory _quizName
  ) external adminOnly whenNotPaused {
    require(
      quizmap[_quizName].creatorAddress != address(0),
      "Quiz doesn't exist"
    );

    // Remove the quiz from the quizNames mapping
    string[] storage quizList = quizNames[_communityName];
    for (uint256 i = 0; i < quizList.length; i++) {
      if (keccak256(bytes(quizList[i])) == keccak256(bytes(_quizName))) {
        // Swap the element to delete with the last element and then pop
        quizList[i] = quizList[quizList.length - 1];
        quizList.pop();
        break;
      }
    }

    // Remove the quiz from the entryLevelQuizNames mapping if necessary
    string[] storage entryQuizList = entryLevelQuizNames[_communityName];
    for (uint256 i = 0; i < entryQuizList.length; i++) {
      if (keccak256(bytes(entryQuizList[i])) == keccak256(bytes(_quizName))) {
        // Swap the element to delete with the last element and then pop
        entryQuizList[i] = entryQuizList[entryQuizList.length - 1];
        entryQuizList.pop();
        break;
      }
    }

    // Delete the quiz from the quizmap mapping
    delete quizmap[_quizName];
  }

  function quizNameExists(
    string memory _communityName,
    string memory _quizName
  ) internal view returns (bool) {
    string[] storage quizList = quizNames[_communityName];
    for (uint256 i = 0; i < quizList.length; i++) {
      if (keccak256(bytes(quizList[i])) == keccak256(bytes(_quizName))) {
        return true;
      }
    }
    return false;
  }

  function getQuizdetails(
    string memory _quizName
  ) public view returns (Quiz memory) {
    return quizmap[_quizName];
  }

  function getstringQuizdetails(
    string memory _quizName
  )
    public
    view
    returns (string memory, string memory, string memory, string[4] memory)
  {
    Quiz memory qtemp = getQuizdetails(_quizName);
    string memory tempDescription = qtemp.description;
    string memory tempImageUrl = qtemp.imageUrl;

    string memory tQuestion = qtemp.question;
    string[4] memory options = qtemp.options;

    return (tempDescription, tempImageUrl, tQuestion, options);
  }

  function isEntryLevelQuiz(
    string memory _communityName,
    string memory _quizName
  ) public view returns (bool) {
    string[] memory entryQuizzes = entryLevelQuizNames[_communityName];
    for (uint256 i = 0; i < entryQuizzes.length; i++) {
      if (keccak256(bytes(entryQuizzes[i])) == keccak256(bytes(_quizName))) {
        return true;
      }
    }
    return false;
  }

  function checkAnswer(
    string memory _quizName,
    bytes32 choice
  ) public view returns (bool) {
    Quiz memory qtemp = getQuizdetails(_quizName);
    // Question memory tempQuestion = qtemp.question;
    bytes32 answer = qtemp.answer;
    if (answer == choice) {
      return true;
    } else {
      return false;
    }
  }

  function getEvalStatus(
    string memory _quizName,
    address _userAddress
  ) public view returns (bool) {
    return evalStatus[_quizName][_userAddress];
  }

  function getEntryLevelQuizNames(
    string memory _communityName
  ) public view returns (string[] memory) {
    require(
      community.checkCommunityExists(_communityName),
      "Community doesn't exist"
    );
    return entryLevelQuizNames[_communityName];
  }

  function getQuizNames(
    string memory _communityName
  ) public view returns (string[] memory) {
    require(
      community.checkCommunityExists(_communityName),
      "Community doesn't exist"
    );
    return quizNames[_communityName];
  }

  function setCommunityContract(
    address _communityContract
  ) external adminOnly whenNotPaused {
    communityContract = _communityContract;
    community = WowTCommunity(_communityContract);
  }

  function setPointsContract(
    address _pointsContract
  ) external adminOnly whenNotPaused {
    pointsContract = _pointsContract;
    points = WowTPoints(_pointsContract);
  }

  function pause() public adminOnly {
    _pause();
  }

  function unpause() public adminOnly {
    _unpause();
  }

  // function deleteAllEntryLevelQuizzes(
  //   string memory _communityName
  // ) external adminOnly whenNotPaused {
  //   uint256 length = entryLevelQuizNames[_communityName].length;
  //   for (uint256 i = 0; i < length; i++) {
  //     entryLevelQuizNames[_communityName].pop();
  //   }
  // }

  // // for development
  // function setQuizImage(
  //     string memory _quizName,
  //     string memory _imageUrl
  // ) external onlyOwner {
  //     quizmap[_quizName].imageUrl = _imageUrl;
  // }
}
