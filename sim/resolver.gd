# Abstract combat for fights outside the player's bubble. It's Lanchester's square
# law: each side loses soldiers in proportion to the other side's firepower, and both
# sides' losses are worked out before either is applied, so neither fires first.
#
# Supply: a squad with no ammo can't shoot, and one running low fires less.
# Fortification: fighting on owned, fortified ground stops part of the incoming fire.
extends RefCounted


static func fight(side_a: Array, side_b: Array, fort_a: float, fort_b: float, dt: float, stats: Dictionary, rng: RandomNumberGenerator) -> void:
	var losses_a := _roll_losses(_incoming(side_b, fort_a, stats) * dt, rng)
	var losses_b := _roll_losses(_incoming(side_a, fort_b, stats) * dt, rng)
	_burn_ammo(side_a, dt, stats)
	_burn_ammo(side_b, dt, stats)
	_apply_losses(side_a, losses_a, rng)
	_apply_losses(side_b, losses_b, rng)


# Soldiers per second the other side is losing to this firepower.
static func _incoming(shooters: Array, fortification: float, stats: Dictionary) -> float:
	var shielded: float = fortification * stats.fortification_protection
	return firepower(shooters, stats) * stats.kill_rate_per_shooter_per_sec * (1.0 - shielded)


static func firepower(squads: Array, stats: Dictionary) -> float:
	var total := 0.0
	for squad in squads:
		if squad.ammo > 0.0:
			total += squad.soldiers * lerpf(stats.low_supply_firepower, 1.0, squad.supply())
	return total


# Expected losses are fractional. The fraction is a chance of one more.
static func _roll_losses(expected: float, rng: RandomNumberGenerator) -> int:
	var whole := int(expected)
	return whole + (1 if rng.randf() < expected - whole else 0)


static func _burn_ammo(squads: Array, dt: float, stats: Dictionary) -> void:
	for squad in squads:
		squad.ammo = maxf(squad.ammo - squad.soldiers * stats.ammo_burn_per_soldier_per_sec * dt, 0.0)


# Each loss lands on a random soldier, so bigger squads take more of them.
static func _apply_losses(squads: Array, losses: int, rng: RandomNumberGenerator) -> void:
	for i in losses:
		var total := 0
		for squad in squads:
			total += squad.soldiers
		if total == 0:
			return
		var pick := rng.randi_range(1, total)
		for squad in squads:
			pick -= squad.soldiers
			if pick <= 0:
				squad.soldiers -= 1
				break
