# SPDX-FileCopyrightText:  PyPSA-Earth and PyPSA-Eur Authors
#
# SPDX-License-Identifier: AGPL-3.0-or-later


HEAT_BASEYEAR = {
    "cop_soil_total": "resources/"
    + SECDIR
    + "cops/cop_soil_total_elec_s{simpl}_{clusters}_{planning_horizons}.nc",
    "cop_air_total": "resources/"
    + SECDIR
    + "cops/cop_air_total_elec_s{simpl}_{clusters}_{planning_horizons}.nc",
    "existing_heating_distribution": "resources/"
    + SECDIR
    + "heating/existing_heating_distribution_s{simpl}_{clusters}_{planning_horizons}.csv",
}


rule add_existing_baseyear:
    params:
        baseyear=config["scenario"]["planning_horizons"][0],
        sector=config["sector"],
        existing_capacities=config["existing_capacities"],
        costs=config["costs"],
    input:
        **branch(sector_enable["heat"], HEAT_BASEYEAR),
        network=RESDIR
        + "prenetworks/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}_export.nc",
        powerplants="resources/" + RDIR + "powerplants.csv",
        busmap_s="resources/" + RDIR + "bus_regions/busmap_elec_s{simpl}.csv",
        busmap="resources/" + RDIR + "bus_regions/busmap_elec_s{simpl}_{clusters}.csv",
        # clustered_pop_layout="resources/"
        # + SECDIR
        # + "population_shares/pop_layout_elec_s{simpl}_{clusters}_{planning_horizons}.csv",
        costs="resources/" + RDIR + "costs_{planning_horizons}_sec.csv",
    output:
        RESDIR
        + "prenetworks-brownfield/elec_s{simpl}_{clusters}_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}.nc",
    wildcard_constraints:
        # TODO: The first planning_horizon needs to be aligned across scenarios
        # snakemake does not support passing functions to wildcard_constraints
        # reference: https://github.com/snakemake/snakemake/issues/2703
        planning_horizons=config["scenario"]["planning_horizons"][0],  #only applies to baseyear
    threads: 1
    resources:
        mem_mb=2000,
    log:
        RESDIR
        + "logs/add_existing_baseyear_elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}.log",
    benchmark:
        RESDIR
        +"benchmarks/add_existing_baseyear/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}"
    script:
        "../scripts/add_existing_baseyear.py"


def input_profile_tech_brownfield(w):
    return {
        f"profile_{tech}": f"resources/" + RDIR + "renewable_profiles/profile_{tech}.nc"
        for tech in config["electricity"]["renewable_carriers"]
        if tech != "hydro"
    }


def solved_previous_horizon(w):
    planning_horizons = config["scenario"]["planning_horizons"]
    i = planning_horizons.index(int(w.planning_horizons))
    planning_horizon_p = str(planning_horizons[i - 1])

    return (
        RESDIR
        + "postnetworks/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_"
        + planning_horizon_p
        + "_{discountrate}.nc"
    )


rule add_brownfield:
    params:
        H2_retrofit=config["sector"]["hydrogen"],
        H2_retrofit_capacity_per_CH4=config["sector"]["hydrogen"][
            "H2_retrofit_capacity_per_CH4"
        ],
        threshold_capacity=config["existing_capacities"]["threshold_capacity"],
        snapshots=config["snapshots"],
        # drop_leap_day=config["enable"]["drop_leap_day"],
        carriers=config["electricity"]["renewable_carriers"],
    input:
        # unpack(input_profile_tech_brownfield),
        simplify_busmap="resources/" + RDIR + "bus_regions/busmap_elec_s{simpl}.csv",
        cluster_busmap="resources/"
        + RDIR
        + "bus_regions/busmap_elec_s{simpl}_{clusters}.csv",
        network=RESDIR
        + "prenetworks/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}_export.nc",
        network_p=solved_previous_horizon,  #solved network at previous time step
        costs="resources/" + RDIR + "costs_{planning_horizons}_sec.csv",
        cop_soil_total="resources/"
        + SECDIR
        + "cops/cop_soil_total_elec_s{simpl}_{clusters}_{planning_horizons}.nc",
        cop_air_total="resources/"
        + SECDIR
        + "cops/cop_air_total_elec_s{simpl}_{clusters}_{planning_horizons}.nc",
    output:
        RESDIR
        + "prenetworks-brownfield/elec_s{simpl}_{clusters}_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}.nc",
    threads: 4
    resources:
        mem_mb=10000,
    log:
        RESDIR
        + "logs/add_brownfield_elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}.log",
    benchmark:
        (
            RESDIR
            + "benchmarks/add_brownfield/elec_s{simpl}_ec_{clusters}_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}"
        )
    script:
        "../scripts/add_brownfield.py"


ruleorder: add_existing_baseyear > add_brownfield


rule solve_network_myopic:
    params:
        solving=config["solving"],
        foresight=config["foresight"],
        planning_horizons=config["scenario"]["planning_horizons"],
        co2_sequestration_potential=config["scenario"].get(
            "co2_sequestration_potential", 200
        ),
        augmented_line_connection=config["augmented_line_connection"],
        policy_config=config["policy_config"],
    input:
        network=RESDIR
        + "prenetworks-brownfield/elec_s{simpl}_{clusters}_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}.nc",
        costs="resources/" + RDIR + "costs_{planning_horizons}_sec.csv",
        configs=SDIR + "configs/config.yaml",  # included to trigger copy_config rule
        agg_p_nom_minmax=config["electricity"]["agg_p_nom_limits"]["file"],  # ensure the CSV with capacity constraints is copied into the shadow directory (needed on Windows, since shadowed scripts can’t access files outside `input`)
    output:
        network=RESDIR
        + "postnetworks/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}.nc",
        # config=RESDIR
        # + "configs/config.elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}.yaml",
    shadow:
        "copy-minimal" if os.name == "nt" else "shallow"
    log:
        solver="logs/"
        + SECDIR
        + "solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}_solver.log",
        python="logs/"
        + SECDIR
        + "solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}_python.log",
        memory="logs/"
        + SECDIR
        + "solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}_memory.log",
    threads: 25
    resources:
        mem_mb=config["solving"]["mem"],
    benchmark:
        (
            RESDIR
            + "benchmarks/solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}"
        )
    script:
        "../scripts/solve_network.py"


rule solve_sector_networks_myopic:
    input:
        networks=expand(
            RESDIR
            + "postnetworks/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}.nc",
            **config["scenario"],
            **config["costs"],
        ),
