class Turret
    export var all

    var v : entity_vars
    var kills : int
    var damage_dealt : int

    forward proc request_new_target ()
    forward proc fire_projectile (u : unchecked ^entity_vars)

    proc initialize (i, tt : int, l : point)
	if tt > 0 then
	    v.cooldown := reload_turrets (tt)
	    v.health := max_healths_turrets (tt)
	else
	    v.cooldown := 1000
	    v.health := 0
	end if
	v.ind := i
	v.cur_target := nil
	v.state := ALIVE
	v.effective_health := v.health
	kills := 0
	damage_dealt := 0
	v.e_type := tt
	v.loc := l
	v.class_type := TURRET
    end initialize

    %update every tick

    proc update ()

	if v.state = NONEXISTENT or v.state = DEAD then
	    return
	end if
	if v.health <= 0 then
	    num_turrets -= 1
	    can_build_turrets := true
	    v.state := DEAD
	    fork play_effect ("Sounds\\turret_destroyed.wav")
	    return
	end if
	if v.cur_target not= nil then
	    if v.cur_target -> state <= DEAD then
		request_new_target ()
	    elsif v.cur_target -> effective_health <= 0 then
		request_new_target ()
	    elsif distance_squared (v.loc, v.cur_target -> loc) > range_turrets (v.e_type) ** 2 then
		request_new_target ()
	    else
		if v.cooldown <= 0 then
		    fire_projectile (v.cur_target)
		end if
	    end if
	else
	    request_new_target ()
	end if
	v.cooldown -= 1
    end update

    %draw
    proc draw ()
	if v.state < ALIVE then
	    return
	end if
	var dsc_x : int := round ((v.loc.x - 0.5) * PIXELS_PER_GRID)
	var dsc_y : int := round ((v.loc.y - 0.5) * PIXELS_PER_GRID)
	Draw.FillOval (dsc_x, dsc_y, PIXELS_PER_GRID, PIXELS_PER_GRID, COLORS (colors_turrets (v.e_type)))

	if v.health < max_healths_turrets (v.e_type) then
	    dsc_x -= PIXELS_PER_GRID
	    dsc_y -= PIXELS_PER_GRID - 1
	    Draw.Line (dsc_x, dsc_y, floor (2 * PIXELS_PER_GRID * v.health / max_healths_turrets (v.e_type)) + dsc_x, dsc_y, brightgreen)
	    Draw.Line (floor (2 * PIXELS_PER_GRID * v.health / max_healths_turrets (v.e_type)) + dsc_x, dsc_y, 2 * PIXELS_PER_GRID + dsc_x, dsc_y, brightred)
	end if
    end draw

    body proc request_new_target ()
	if not turret_on_standby (v.ind) then
	    turret_on_standby (v.ind) := true
	    turrets_on_standby += 1
	end if
    end request_new_target

    body proc fire_projectile (u : unchecked ^entity_vars)
	if not can_fire then
	    return
	end if
	if prod_per_proj (v.e_type) < 0 then
	    if electricity_stored < 5 then
		return
	    end if
	    electricity_stored -= 5
	else
	    if num_proj_avail (v.e_type) <= 0 then
		return
	    end if
	    num_proj_avail (v.e_type) -= 1
	end if

	if proj_damage (v.e_type) > 0 then
	    proj_queue (next_proj_queue).target := u
	else
	    cheat (addressint, proj_queue (next_proj_queue).target) := addr (map_handler
		(max (1, min (MAP_WIDTH, floor (Rand.Int (-1, 0) + Rand.Int (0, 1) + u -> loc.x))))
		(max (1, min (MAP_HEIGHT, floor (Rand.Int (-1, 0) + Rand.Int (0, 1) + u -> loc.y)))))
	    if Rand.Real < 0.1 then
		request_new_target
	    end if
	end if
	%proj_queue (next_proj_queue).target_type := u.class_type
	proj_queue (next_proj_queue).p_type := proj_turrets (v.e_type)
	proj_queue (next_proj_queue).loc := v.loc
	proj_queue (next_proj_queue).state := ALIVE

	proj_queue (next_proj_queue).dmg := real_damage (proj_damage (proj_turrets (v.e_type)), proj_dmg_type (proj_turrets (v.e_type)), armor_enemies (u -> e_type))

	if proj_dmg_type (proj_turrets (v.e_type)) not= 3 then
	    damage_dealt += proj_queue (next_proj_queue).dmg
	    u -> effective_health -= proj_queue (next_proj_queue).dmg
	    if u -> effective_health <= 0 then
		kills += 1
	    end if
	end if

	next_proj_queue := (next_proj_queue mod PROJ_QUEUE_NUM) + 1
	num_proj_queue += 1
	if num_proj_queue >= PROJ_QUEUE_NUM then
	    can_fire := false
	end if

	v.cooldown := reload_turrets (v.e_type)

	fork play_effect ("Sounds\\Effects\\turret_shot_" + intstr (v.e_type) + ".wav")
    end fire_projectile

end Turret
