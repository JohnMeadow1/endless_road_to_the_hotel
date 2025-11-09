extends Node

const GAME_WIDTH: int = 1000
const GAME_HEIGHT: int = 600
const GROUND_Y: float = GAME_HEIGHT - 30.0

const GRAVITY: float = 1800.0
const PLAYER_JUMP_VELOCITY: float = -750.0


const INITIAL_ZOOM: float = 1.0
const MAX_ZOOM: float = 2.0
const ZOOM_INCREMENT: float = 0.001
const PLAYER_INITIAL_X: float = 150.0
const PLAYER_TARGET_X: float = 600.0
const PLAYER_MOVEMENT_SPEED: float = 0.002

const BOSS_INITIAL_X: float = Globals.GAME_WIDTH - 130.0
const BOSS_TARGET_X: float = 700.0
const BOSS_MOVEMENT_SPEED: float = 0.001

const BOSS_ANIMATION_DURATION_MS: int = 300
const BOSS_ATTACK_DELAY_MS: int = 200

const INITIAL_GAME_SPEED: float = 2.0
const GAME_SPEED_INCREMENT: float = 0.005

var game_speed: float = Globals.INITIAL_GAME_SPEED

var factory:Node
