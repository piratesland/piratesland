const PLTToken = artifacts.require("PLTToken");

module.exports = function (deployer) {
  deployer.deploy(PLTToken);
};
