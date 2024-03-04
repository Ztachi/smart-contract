// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Comment {
    struct User {
        address addr; //地址
        string comment; //评论
        uint timestamp; //时间
    }

    User[] public comments;

    function sendComment(string calldata content) public {
        User memory current = User({
            addr: msg.sender,
            comment: content,
            timestamp: block.timestamp
        });
        comments.push(current);
    }

    function getComments() public view returns (User[] memory) {
        return comments;
    }
}
