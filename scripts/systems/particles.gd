extends Node
## Pembaruan partikel (dari systems/particles.js). Autoload: Particles.


func update_particles() -> void:
	var sf: float = TimeStop.enemy_slow_factor()
	var kept: Array = []
	for p in State.particle_list:
		p.x += p.vx * sf
		p.y += p.vy * sf
		p.vx *= pow(0.97, sf)
		p.vy = p.vy * pow(0.97, sf) + 0.08 * sf
		p.life -= sf
		if p.life > 0:
			kept.append(p)
	if kept.size() > 300:
		kept.resize(300)
	State.particle_list = kept
