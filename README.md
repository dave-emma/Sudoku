# Sudoku Smart Contract

A decentralized Sudoku puzzle game built on the Stacks blockchain using Clarity smart contracts. Players can solve Sudoku puzzles of varying difficulty levels and earn STX rewards for correct solutions.

## Overview

This smart contract allows a contract owner to create Sudoku puzzles with different difficulty levels, while players compete to solve them for cryptocurrency rewards. Each puzzle can only be solved once, and player statistics are tracked on-chain.

## Features

- **Three Difficulty Levels**: Easy, Medium, and Hard puzzles with proportional rewards
- **Automatic Rewards**: Players receive STX instantly upon solving puzzles correctly
- **One-Time Solutions**: Each puzzle can only be solved once
- **Player Statistics**: Track your solved puzzles and total earnings
- **Secure Validation**: Solutions are verified against stored answers
- **Transparent**: All puzzle data (except solutions) is publicly viewable

## Reward Structure

| Difficulty | Reward |
|------------|--------|
| Easy       | 1 STX  |
| Medium     | 2.5 STX|
| Hard       | 5 STX  |

## Smart Contract Functions

### Public Functions

#### `fund-contract`
```clarity
(fund-contract (amount uint))
```
Funds the contract with STX to pay out rewards. Anyone can fund the contract.

**Parameters:**
- `amount`: Amount of microSTX to deposit (1 STX = 1,000,000 microSTX)

**Returns:** `(ok true)` on success

---

#### `create-puzzle`
```clarity
(create-puzzle (puzzle (list 81 uint)) (solution (list 81 uint)) (difficulty (string-ascii 10)))
```
Creates a new Sudoku puzzle. **Owner only.**

**Parameters:**
- `puzzle`: List of 81 numbers representing the 9x9 grid (0 = empty cell, 1-9 = filled)
- `solution`: Complete solution as a list of 81 numbers (all 1-9)
- `difficulty`: String "easy", "medium", or "hard"

**Returns:** `(ok puzzle-id)` with the new puzzle ID

**Example:**
```clarity
;; A simple puzzle (first row: 5,3,0,0,7,0,0,0,0)
(create-puzzle 
  (list u5 u3 u0 u0 u7 u0 u0 u0 u0 ... /* 72 more numbers */)
  (list u5 u3 u4 u6 u7 u8 u9 u1 u2 ... /* 72 more numbers */)
  "easy")
```

---

#### `solve-puzzle`
```clarity
(solve-puzzle (puzzle-id uint) (solution (list 81 uint)))
```
Submit a solution to an unsolved puzzle. Receive rewards for correct answers.

**Parameters:**
- `puzzle-id`: ID of the puzzle to solve
- `solution`: Your complete solution as a list of 81 numbers

**Returns:** `(ok reward-amount)` on successful solve

**Example:**
```clarity
(solve-puzzle u1 
  (list u5 u3 u4 u6 u7 u8 u9 u1 u2 ... /* 72 more numbers */))
```

---

### Read-Only Functions

#### `get-puzzle`
```clarity
(get-puzzle (puzzle-id uint))
```
Retrieve puzzle details (without the solution).

**Returns:**
```clarity
{
  puzzle: (list 81 uint),
  difficulty: (string-ascii 10),
  reward: uint,
  solved: bool,
  solver: (optional principal)
}
```

---

#### `get-player-stats`
```clarity
(get-player-stats (player principal))
```
Get statistics for a specific player.

**Returns:**
```clarity
{
  puzzles-solved: uint,
  total-earned: uint
}
```

---

#### `get-puzzle-count`
```clarity
(get-puzzle-count)
```
Returns the total number of puzzles created.

---

#### `get-contract-balance`
```clarity
(get-contract-balance)
```
Returns the current contract balance in microSTX.

---

#### `is-puzzle-solved`
```clarity
(is-puzzle-solved (puzzle-id uint))
```
Check if a specific puzzle has been solved.

---

## How to Use

### For Contract Owner

1. **Deploy the Contract**
   ```bash
   clarinet contract deploy sudoku
   ```

2. **Fund the Contract**
   ```clarity
   (contract-call? .sudoku fund-contract u10000000) ;; Fund with 10 STX
   ```

3. **Create Puzzles**
   ```clarity
   (contract-call? .sudoku create-puzzle 
     (list u5 u3 u0 ...) 
     (list u5 u3 u4 ...) 
     "medium")
   ```

### For Players

1. **View Available Puzzles**
   ```clarity
   (contract-call? .sudoku get-puzzle u1)
   ```

2. **Solve a Puzzle**
   ```clarity
   (contract-call? .sudoku solve-puzzle u1 
     (list u5 u3 u4 u6 u7 u8 u9 u1 u2 ...))
   ```

3. **Check Your Stats**
   ```clarity
   (contract-call? .sudoku get-player-stats tx-sender)
   ```

## Puzzle Format

Puzzles are represented as a flat list of 81 numbers:
- **Index 0-8**: Row 1
- **Index 9-17**: Row 2
- **Index 18-26**: Row 3
- And so on...

**Values:**
- `0`: Empty cell (in puzzle template)
- `1-9`: Filled cell with that number

**Example 9x9 Grid:**
```
5 3 0 | 0 7 0 | 0 0 0
6 0 0 | 1 9 5 | 0 0 0
0 9 8 | 0 0 0 | 0 6 0
------+-------+------
8 0 0 | 0 6 0 | 0 0 3
4 0 0 | 8 0 3 | 0 0 1
7 0 0 | 0 2 0 | 0 0 6
------+-------+------
0 6 0 | 0 0 0 | 2 8 0
0 0 0 | 4 1 9 | 0 0 5
0 0 0 | 0 8 0 | 0 7 9
```

Becomes: `(list u5 u3 u0 u0 u7 u0 u0 u0 u0 u6 u0 u0 ...)`

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | err-owner-only | Only contract owner can perform this action |
| u101 | err-invalid-puzzle | Puzzle format is invalid (must be 81 numbers) |
| u102 | err-invalid-solution | Solution is incorrect or invalid |
| u103 | err-puzzle-not-found | Puzzle ID does not exist |
| u104 | err-already-solved | This puzzle has already been solved |
| u105 | err-insufficient-funds | Contract doesn't have enough STX for reward |

## Security Considerations

- Solutions are stored on-chain but only accessible by the contract
- Players cannot view solutions before solving
- Each puzzle can only be claimed once
- Contract balance is tracked to prevent over-payment
- Only the contract owner can create puzzles

## Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity and Stacks blockchain

### Testing
```bash
clarinet test
```

### Local Deployment
```bash
clarinet integrate
```

## License

This smart contract is open source and available for educational purposes.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Support

For issues or questions, please open an issue on the repository.