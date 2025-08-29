import freeflowuniverse.herolib.threefold.incatokens
import freeflowuniverse.herolib.core.playcmds
import os

const heroscript_path = os.dir(@FILE) + '/data'

fn main() {
    playcmds.run(
        heroscript_path: heroscript_path
    )!
    println('Simulation complete!')
}