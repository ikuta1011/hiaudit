//No additional token amount to be distributed later
//Distribution can start at a set date and time for all members
//One month's worth of tokens can be withdrawn as soon as the vesting period starts

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PVXTokenVesting is Ownable, ReentrancyGuard{
    using SafeERC20 for IERC20;

    struct Investor {
        uint256 totalAllocation;
        uint256 amountWithdrawn;
        bool isInvestor;
    }

    IERC20 public pvxToken;
    uint256 public constant VESTING_DURATION = 48 * 30 days; // 48 months approximated as 30 days each
    uint256 public vestingStartTime;
    uint256 public constant TOTAL_VESTING_MONTHS = 48;
    uint256 public constant DAYS_PER_MONTH = 30 days;
    address private _newOwner;

    mapping(address => Investor) public investors;

    event TokensReleased(address investor, uint256 amount);
    event InvestorAdded(address indexed _investor, uint256 _allocation);

    modifier onlyInvestor {
        require(investors[msg.sender].isInvestor, "Not investor");
        _;
    }

    constructor(address _pvxTokenAddress, uint256 _vestingStart) {
        require(_pvxTokenAddress != address(0), "PVXTokenVesting: token address is the zero address");
        require(_vestingStart > block.timestamp, "PVXTokenVesting: vesting start is not in the future");

        pvxToken = IERC20(_pvxTokenAddress);
        vestingStartTime = _vestingStart;
    }

    function addInvestor(address _investor, uint256 _allocation) public onlyOwner {
        require(block.timestamp < vestingStartTime, "Cannot add investors after vesting has started");
        require(_allocation > 0, "Allocation must be greater than 0");
        require(!investors[_investor].isInvestor, "Investor already added");
        pvxToken.safeTransferFrom(msg.sender, address(this), _allocation);
        
        investors[_investor] = Investor(_allocation, 0, true);
        emit InvestorAdded(_investor, _allocation);
    }

    // Function to release token
    function releaseTokens() external nonReentrant onlyInvestor {
        Investor storage investor = investors[msg.sender];
        require(block.timestamp >= vestingStartTime, "Vesting period not started");
        
        
        uint256 monthsPassed = (block.timestamp - vestingStartTime) / DAYS_PER_MONTH;
        monthsPassed = monthsPassed > TOTAL_VESTING_MONTHS ? TOTAL_VESTING_MONTHS : monthsPassed;

        uint256 totalAvailable;
        if (monthsPassed >= TOTAL_VESTING_MONTHS) {
            totalAvailable = investor.totalAllocation; // If the vesting period is over, the investor can claim all their tokens
        } else {
            uint256 amountPerMonth = investor.totalAllocation / TOTAL_VESTING_MONTHS;//Vesting is for a total of 48 months.
            totalAvailable = amountPerMonth * monthsPassed;
        }

        uint256 amountToWithdraw = totalAvailable - investor.amountWithdrawn;
        require(amountToWithdraw > 0, "No tokens available for withdrawal");
        investor.amountWithdrawn += amountToWithdraw;
        pvxToken.safeTransfer(msg.sender, amountToWithdraw);
        emit TokensReleased(msg.sender, amountToWithdraw);
    }

    // Function to pool tokens in a contract
    function poolTokens(uint256 _amount) external onlyOwner {
        pvxToken.safeTransferFrom(msg.sender, address(this), _amount); 
    }

    // Function to check the balance available to a particular investor
    function availableBalance(address _investor) public view returns (uint256) {
        Investor storage investor = investors[_investor];
        if (block.timestamp < vestingStartTime) {
            return 0;
        } else {
            uint256 monthsPassed = (block.timestamp - vestingStartTime)/ DAYS_PER_MONTH;
            monthsPassed = monthsPassed > TOTAL_VESTING_MONTHS ? TOTAL_VESTING_MONTHS : monthsPassed;
            
            uint256 totalAvailable;
            if (monthsPassed >= TOTAL_VESTING_MONTHS) {
                totalAvailable = investor.totalAllocation; // If the vesting period is over, the investor can see all their allocated tokens as available
            } else {
                uint256 amountPerMonth = investor.totalAllocation / TOTAL_VESTING_MONTHS;
                totalAvailable = amountPerMonth * monthsPassed;
            }
            uint256 remainingBalance = totalAvailable - investor.amountWithdrawn;
            return remainingBalance;
        }
    }

    function renounceOwnership() public override onlyOwner {
        revert("Ownership cannot be renounced");
    }

    function proposeNewOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _newOwner = newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == _newOwner, "Only proposed new owner can accept ownership");
        _transferOwnership(_newOwner);
        _newOwner = address(0);
    }

}
