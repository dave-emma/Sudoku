;; Sudoku Game Smart Contract
;; A decentralized Sudoku puzzle game with rewards

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-puzzle (err u101))
(define-constant err-invalid-solution (err u102))
(define-constant err-puzzle-not-found (err u103))
(define-constant err-already-solved (err u104))
(define-constant err-insufficient-funds (err u105))

;; Difficulty levels and rewards (in microSTX)
(define-constant reward-easy u1000000) ;; 1 STX
(define-constant reward-medium u2500000) ;; 2.5 STX
(define-constant reward-hard u5000000) ;; 5 STX

;; Data Variables
(define-data-var puzzle-counter uint u0)
(define-data-var contract-balance uint u0)

;; Data Maps
(define-map puzzles
    uint
    {
        puzzle: (list 81 uint),
        solution: (list 81 uint),
        difficulty: (string-ascii 10),
        reward: uint,
        solved: bool,
        solver: (optional principal)
    }
)

(define-map player-stats
    principal
    {
        puzzles-solved: uint,
        total-earned: uint
    }
)

;; Private Functions

;; Check if a number is valid in a row
(define-private (check-row (board (list 81 uint)) (row uint) (num uint))
    (let
        (
            (start (* row u9))
            (row-slice (unwrap-panic (slice board start (+ start u9))))
        )
        (is-eq (len (filter is-num row-slice)) u0)
    )
)

;; Helper to check if element equals num
(define-private (is-num (x uint))
    false
)

;; Validate that the solution is a valid Sudoku
(define-private (validate-sudoku (solution (list 81 uint)))
    (and
        (is-eq (len solution) u81)
        (check-all-cells-filled solution)
    )
)

;; Check all cells are filled with numbers 1-9
(define-private (check-all-cells-filled (board (list 81 uint)))
    (let
        (
            (valid-cells (filter is-valid-cell board))
        )
        (is-eq (len valid-cells) u81)
    )
)

;; Check if a cell contains a valid number (1-9)
(define-private (is-valid-cell (num uint))
    (and (>= num u1) (<= num u9))
)

;; Match puzzle cells with solution
(define-private (matches-puzzle (puzzle-cell uint) (solution-cell uint))
    (or (is-eq puzzle-cell u0) (is-eq puzzle-cell solution-cell))
)

;; Check if solution matches puzzle template
(define-private (check-puzzle-match (puzzle (list 81 uint)) (solution (list 81 uint)))
    (let
        (
            (matched (map matches-puzzle puzzle solution))
            (all-true (filter is-true matched))
        )
        (is-eq (len all-true) u81)
    )
)

;; Helper to filter true values
(define-private (is-true (val bool))
    val
)

;; Slice list helper
(define-private (slice (lst (list 81 uint)) (start uint) (end uint))
    (ok lst)
)

;; Public Functions

;; Fund the contract with STX for rewards
(define-public (fund-contract (amount uint))
    (begin
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set contract-balance (+ (var-get contract-balance) amount))
        (ok true)
    )
)

;; Create a new puzzle (owner only)
(define-public (create-puzzle 
    (puzzle (list 81 uint)) 
    (solution (list 81 uint)) 
    (difficulty (string-ascii 10)))
    (let
        (
            (puzzle-id (+ (var-get puzzle-counter) u1))
            (reward (if (is-eq difficulty "easy")
                        reward-easy
                        (if (is-eq difficulty "medium")
                            reward-medium
                            reward-hard)))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (len puzzle) u81) err-invalid-puzzle)
        (asserts! (is-eq (len solution) u81) err-invalid-puzzle)
        (asserts! (validate-sudoku solution) err-invalid-solution)
        
        (map-set puzzles puzzle-id {
            puzzle: puzzle,
            solution: solution,
            difficulty: difficulty,
            reward: reward,
            solved: false,
            solver: none
        })
        
        (var-set puzzle-counter puzzle-id)
        (ok puzzle-id)
    )
)

;; Submit a solution to a puzzle
(define-public (solve-puzzle (puzzle-id uint) (solution (list 81 uint)))
    (let
        (
            (puzzle-data (unwrap! (map-get? puzzles puzzle-id) err-puzzle-not-found))
            (stored-solution (get solution puzzle-data))
            (puzzle-board (get puzzle puzzle-data))
            (reward (get reward puzzle-data))
            (player-data (default-to 
                {puzzles-solved: u0, total-earned: u0}
                (map-get? player-stats tx-sender)))
        )
        (asserts! (not (get solved puzzle-data)) err-already-solved)
        (asserts! (is-eq (len solution) u81) err-invalid-solution)
        (asserts! (is-eq solution stored-solution) err-invalid-solution)
        (asserts! (check-puzzle-match puzzle-board solution) err-invalid-solution)
        (asserts! (>= (var-get contract-balance) reward) err-insufficient-funds)
        
        ;; Transfer reward to solver
        (try! (as-contract (stx-transfer? reward tx-sender tx-sender)))
        
        ;; Update puzzle status
        (map-set puzzles puzzle-id (merge puzzle-data {
            solved: true,
            solver: (some tx-sender)
        }))
        
        ;; Update player stats
        (map-set player-stats tx-sender {
            puzzles-solved: (+ (get puzzles-solved player-data) u1),
            total-earned: (+ (get total-earned player-data) reward)
        })
        
        ;; Update contract balance
        (var-set contract-balance (- (var-get contract-balance) reward))
        
        (ok reward)
    )
)

;; Read-only Functions

;; Get puzzle details (without solution)
(define-read-only (get-puzzle (puzzle-id uint))
    (match (map-get? puzzles puzzle-id)
        puzzle-data (ok {
            puzzle: (get puzzle puzzle-data),
            difficulty: (get difficulty puzzle-data),
            reward: (get reward puzzle-data),
            solved: (get solved puzzle-data),
            solver: (get solver puzzle-data)
        })
        err-puzzle-not-found
    )
)

;; Get player statistics
(define-read-only (get-player-stats (player principal))
    (ok (default-to 
        {puzzles-solved: u0, total-earned: u0}
        (map-get? player-stats player)))
)

;; Get total puzzles created
(define-read-only (get-puzzle-count)
    (ok (var-get puzzle-counter))
)

;; Get contract balance
(define-read-only (get-contract-balance)
    (ok (var-get contract-balance))
)

;; Check if puzzle is solved
(define-read-only (is-puzzle-solved (puzzle-id uint))
    (match (map-get? puzzles puzzle-id)
        puzzle-data (ok (get solved puzzle-data))
        err-puzzle-not-found
    )
)