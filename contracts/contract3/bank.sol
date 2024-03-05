// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Bank {
    //上帝权限
    address private immutable owner;
    //管理员
    mapping(address => bool) administrators;
    //交易信息
    struct TransactionInfo {
        uint256 timestamp; //最后交易时间戳
        string category; //最后交易类别
        uint256 value; //最后交易值
    }

    //用户信息
    struct UserInfo {
        uint256 balance; //余额
        TransactionInfo[] transactionLog; //交易流水
    }

    uint256 private _status; // 重入锁

    //保存所有信息
    mapping(address => UserInfo) public dataBase;
    //保存所有用户的address
    address[] private allUserAddresses;
    //保存所有管理员的address
    address[] private allAdminAddresses;

    constructor() {
        //设置上帝权限
        owner = msg.sender;
    }

    //添加用户地址
    function addUserAddress(address userAddress) private {
        //没记录过就记录地址
        if (dataBase[userAddress].transactionLog.length == 0) {
            allUserAddresses.push(userAddress);
        }
    }

    //删除用户
    function delUserAddresses(address userAddress) private {
        //记录过就删除
        if (dataBase[userAddress].transactionLog.length > 0) {
            //从保存的key数组删除
            uint256 length = allUserAddresses.length;
            if (length == 1) {
                delete allUserAddresses;
            } else {
                address last = allUserAddresses[length - 1];
                uint256 i = 0;
                while (allUserAddresses[i] != userAddress) {
                    i++;
                }
                allUserAddresses[length - 1] = allUserAddresses[i];
                allUserAddresses[i] = last;
                allUserAddresses.pop();
            }
            //从mapping删除
            delete dataBase[userAddress];
        }
    }

    //存款事件
    event Deposit(address indexed accountAddress, uint256 amount);
    //取款事件
    event Withdraw(address indexed accountAddress, uint256 amount);
    //错误事件
    event ErrorEvent(uint256 indexed timestamp);

    //上帝权限判断
    modifier onlyOwner() {
        require(msg.sender == owner, "Forbidden.");
        _;
    }

    //管理员权限判断
    modifier AdministratorPlus() {
        require(
            msg.sender == owner || administrators[msg.sender],
            "Forbidden."
        );
        _;
    }

    // 重入锁
    modifier nonReentrant() {
        // 在第一次调用 nonReentrant 时，_status 将是 0
        require(_status == 0, "ReentrancyGuard: reentrant call");
        // 在此之后对 nonReentrant 的任何调用都将失败
        _status = 1;
        _;
        // 调用结束，将 _status 恢复为0
        _status = 0;
    }

    // 存钱
    receive() external payable {
        //记录用户地址
        addUserAddress(msg.sender);
        //存
        dataBase[msg.sender].balance += msg.value;
        dataBase[msg.sender].transactionLog.push(
            TransactionInfo({
                timestamp: block.timestamp,
                category: "deposit",
                value: msg.value
            })
        );

        emit Deposit(msg.sender, msg.value);
    }

    // 存钱
    function deposit() external payable {
        //记录用户地址
        addUserAddress(msg.sender);
        //存
        dataBase[msg.sender].balance += msg.value;
        dataBase[msg.sender].transactionLog.push(
            TransactionInfo({
                timestamp: block.timestamp,
                category: "deposit",
                value: msg.value
            })
        );

        emit Deposit(msg.sender, msg.value);
    }

    //取钱
    function withdraw(uint256 value) public payable nonReentrant {
        //余额
        uint256 balance = dataBase[msg.sender].balance;
        //余额不足就无法取钱
        require(balance >= value, "not sufficient funds");

        //取钱
        (bool success, ) = payable(msg.sender).call{value: value}("");
        require(success, "Transfer failed");

        //记录
        dataBase[msg.sender].balance = balance - value;
        dataBase[msg.sender].transactionLog.push(
            TransactionInfo({
                timestamp: block.timestamp,
                category: "withdraw",
                value: value
            })
        );

        emit Withdraw(msg.sender, value);
    }

    //取所有钱
    function withdrawAll() public payable nonReentrant {
        //余额
        uint256 balance = dataBase[msg.sender].balance;
        //余额不足就无法取钱
        require(balance > 0, "not sufficient funds");
        //取钱
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Transfer failed");
        //记录
        dataBase[msg.sender].balance = 0;
        dataBase[msg.sender].transactionLog.push(
            TransactionInfo({
                timestamp: block.timestamp,
                category: "withdraw",
                value: balance
            })
        );
        emit Withdraw(msg.sender, balance);
    }

    //查看总存款额度
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //获取用户列表
    function getUserList()
        public
        view
        AdministratorPlus
        returns (address[] memory)
    {
        return allUserAddresses;
    }

    //获取用户
    function getUser(address addr)
        public
        view
        AdministratorPlus
        returns (UserInfo memory)
    {
        return dataBase[addr];
    }

    //添加管理员
    function addAdministrator(address addr) public onlyOwner {
        //没记录过就记录地址
        if (administrators[addr] == false) {
            allAdminAddresses.push(addr);
            administrators[addr] = true;
        }
    }

    //删除管理员
    function deleteAdministrator(address adminAddress) public onlyOwner {
        //记录过就删除地址
        if (administrators[adminAddress] == true) {
            //从保存的key数组删除
            uint256 length = allAdminAddresses.length;
            if (length == 1) {
                delete allAdminAddresses;
            } else {
                address last = allAdminAddresses[allAdminAddresses.length - 1];
                uint256 i = 0;
                while (allAdminAddresses[i] != adminAddress) {
                    i++;
                }
                allAdminAddresses[
                    allAdminAddresses.length - 1
                ] = allAdminAddresses[i];
                allAdminAddresses[i] = last;
                allAdminAddresses.pop();
            }
            //从mapping删除
            delete administrators[adminAddress];
        }
    }

    //获取管理员列表
    function getAdministratorList()
        public
        view
        AdministratorPlus
        returns (address[] memory)
    {
        return allAdminAddresses;
    }

    //销户
    function destroyingAccount(address addr) public onlyOwner {
        //退款
        //余额
        uint256 balance = dataBase[addr].balance;
        if (balance > 0) {
            (bool success, ) = payable(addr).call{value: balance}("");
            require(success, "Transfer failed");
        }
        //删除数据
        delUserAddresses(addr);
    }

    //是否是管理员
    function checkIsAdministrator() public view returns (bool) {
        return owner == msg.sender || administrators[msg.sender];
    }

    //是否是上帝
    function checkIsGod() public view returns (bool) {
        return owner == msg.sender;
    }

    fallback() external {
        emit ErrorEvent(block.timestamp);
        revert("error in operation");
    }
}
