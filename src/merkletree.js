const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

// userAdmin:  0x3aa545813e9b4755328Ddeb820b5F098263a9136
// heavenGame2:  0x1bA72dEe1fc71D0d024FCE98951f7eA7D219E298
let whitelistAddresses = [
    '0x3aa545813e9b4755328Ddeb820b5F098263a9136', // userAdmin
    '0x1bA72dEe1fc71D0d024FCE98951f7eA7D219E298' // heavenGame2
];
let leafNodes = whitelistAddresses.map(address => keccak256(address));
let tree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });

console.log('Tree: ', tree.toString());

let root = tree.getRoot();
console.log('Root hash is: ', root.toString('hex'));
console.log('Root: ', tree.getHexRoot()); // root: 0x162c84fc10af443b77bd74cac127562c7a1650d940ea850ca4017152863d8281

let leaf = keccak256('0x1bA72dEe1fc71D0d024FCE98951f7eA7D219E298'); // heavenGame2
let proof = tree.getHexProof(leaf);
console.log('Proof of 0x1bA72dEe1fc71D0d024FCE98951f7eA7D219E298: ', proof);
// heavenGame2 - proof: 0xcf35cc271f7afbaa4ae6d57c87db8efc82e3badbbccf985b1034cff2126b3f2a