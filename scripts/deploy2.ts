import { ethers } from 'hardhat';

async function main() {
  // 1. Deploy GameToken
  const GameTokenFactory = await ethers.getContractFactory('GameToken');
  const initialSupply = ethers.parseEther('1000');
  const gameToken = await GameTokenFactory.deploy(initialSupply);
  await gameToken.waitForDeployment();
  console.log('GameToken deployed to:', gameToken.target);

  // 2. Deploy Avatars
  const AvatarsFactory = await ethers.getContractFactory('Avatars');
  const avatars = await AvatarsFactory.deploy();
  await avatars.waitForDeployment();
  console.log('Avatars deployed to:', avatars.target);

  // 3. Deploy BoxSales
  const BoxSalesFactory = await ethers.getContractFactory('BoxSales');
  const boxSales = await BoxSalesFactory.deploy(gameToken.target, avatars.target);
  await boxSales.waitForDeployment();
  console.log('BoxSales deployed to:', boxSales.target);

  // 4. Set BoxSales address in Avatars
  await avatars.setBoxSalesAddress(boxSales.target);
  console.log('BoxSales address set in Avatars contract');

  // 5. Add BoxSales as a minter in GameToken
  await gameToken.addMinter(boxSales.target);
  console.log('BoxSales added as a minter for GameToken');
}

// We recommend this pattern to be able to use async/await everywhere and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
