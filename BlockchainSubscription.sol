// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionService {
    struct SubscriptionPlan {
        uint256 price;
        uint256 duration; // in seconds
    }
    
    struct Subscriber {
        uint256 expiry;
        uint8 tier; // 1 for basic, 2 for premium
    }
    
    address public owner;
    mapping(uint256 => SubscriptionPlan) public plans;
    mapping(address => Subscriber) public subscribers;
    mapping(uint8 => string[]) private tieredContent; // 1 for basic, 2 for premium

    event Subscribed(address indexed user, uint256 planId, uint256 expiry);
    event Unsubscribed(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        // Example: adding some plans
        plans[1] = SubscriptionPlan(0.01 ether, 30 days); // Basic plan
        plans[2] = SubscriptionPlan(0.05 ether, 180 days); // Premium plan
    }

    function subscribe(uint256 planId) external payable {
        SubscriptionPlan memory plan = plans[planId];
        require(plan.price > 0, "Invalid plan");
        require(msg.value == plan.price, "Incorrect Ether sent");

        uint8 tier = (planId == 2) ? 2 : 1; // Determine tier based on plan ID

        if (subscribers[msg.sender].expiry < block.timestamp) {
            subscribers[msg.sender].expiry = block.timestamp + plan.duration;
        } else {
            subscribers[msg.sender].expiry += plan.duration;
        }
        subscribers[msg.sender].tier = tier;

        emit Subscribed(msg.sender, planId, subscribers[msg.sender].expiry);
    }

    function unsubscribe() external {
        require(subscribers[msg.sender].expiry > block.timestamp, "Not subscribed");
        
        subscribers[msg.sender].expiry = 0;
        
        emit Unsubscribed(msg.sender);
    }

    function isSubscribed(address user) external view returns (bool) {
        return subscribers[user].expiry > block.timestamp;
    }

    function getContent(uint8 tier) external view returns (string[] memory) {
        require(subscribers[msg.sender].expiry > block.timestamp, "Not subscribed");
        require(subscribers[msg.sender].tier >= tier, "This content is only available to Premium members, upgrade your plan");
        
        return tieredContent[tier];
    }

    function addContent(uint8 tier, string memory cid) external onlyOwner {
        require(tier == 1 || tier == 2, "Invalid tier");
        tieredContent[tier].push(cid);
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
