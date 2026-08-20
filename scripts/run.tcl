# ============================================================
# Fault Tolerant FIR Project
# Vivado 2020.2
# ZedBoard / Zynq-7000
# ============================================================

# ------------------------------------------------------------
# Find project root from location of this TCL script
# ------------------------------------------------------------

set SCRIPT_DIR  [file normalize [file dirname [info script]]]
set PROJECT_DIR [file normalize [file join $SCRIPT_DIR ".."]]

set PROJECT_NAME "dsong_proj"

# ------------------------------------------------------------
# FPGA / Board information extracted from original .xpr
# ------------------------------------------------------------

set FPGA_PART "xc7z020clg484-1"
set BOARD_PART "em.avnet.com:zed:part0:1.4"

# ------------------------------------------------------------
# Top modules extracted from original .xpr
# ------------------------------------------------------------

set RTL_TOP "fir"
set SIM_TOP "fir_tb"

# ------------------------------------------------------------
# Project directories
# ------------------------------------------------------------

set SOURCE_DIR     [file join $PROJECT_DIR "sources"]
set SIM_SOURCE_DIR [file join $PROJECT_DIR "simulation_sources"]
set CONSTRAINT_DIR [file join $PROJECT_DIR "constraints"]

# ------------------------------------------------------------
# Project file
# ------------------------------------------------------------

set PROJECT_FILE [file join $PROJECT_DIR "${PROJECT_NAME}.xpr"]


puts ""
puts "============================================================"
puts " Creating Fault Tolerant FIR Vivado Project"
puts "============================================================"
puts ""
puts "Project directory:"
puts "  $PROJECT_DIR"
puts ""
puts "FPGA:"
puts "  $FPGA_PART"
puts ""
puts "Board:"
puts "  $BOARD_PART"
puts ""
puts "RTL top:"
puts "  $RTL_TOP"
puts ""
puts "Simulation top:"
puts "  $SIM_TOP"
puts ""


# ============================================================
# Remove old project if it exists
# ============================================================

if {[file exists $PROJECT_FILE]} {

    puts "Existing project found:"
    puts "  $PROJECT_FILE"

    close_project -quiet

    file delete -force $PROJECT_FILE

    # Vivado generated project directories
    foreach dir {
        ".Xil"
        "dsong_proj.cache"
        "dsong_proj.gen"
        "dsong_proj.hw"
        "dsong_proj.ip_user_files"
        "dsong_proj.runs"
        "dsong_proj.sim"
    } {
        set path [file join $PROJECT_DIR $dir]

        if {[file exists $path]} {
            puts "Removing: $path"
            file delete -force $path
        }
    }
}


# ============================================================
# Create project
# ============================================================

puts "Creating Vivado project..."

create_project \
    $PROJECT_NAME \
    $PROJECT_DIR \
    -part $FPGA_PART \
    -force


# ============================================================
# Set board
# ============================================================

puts "Setting board part..."

if {[catch {
    set_property board_part $BOARD_PART [current_project]
} err]} {

    puts "WARNING:"
    puts "Could not set board part:"
    puts "  $BOARD_PART"
    puts ""
    puts "Make sure the ZedBoard board files are installed."
}


# ============================================================
# Project language settings
# ============================================================

set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]


# ============================================================
# Add RTL source files
# ============================================================

puts ""
puts "============================================================"
puts " Adding RTL sources"
puts "============================================================"

set rtl_files {

    param_package.vhd
    fault_detector.vhd
    util_pkg.vhd
    mac.vhd
    pair_n_spare.vhd
    redundancy_unit.vhd
    redundancy_voter.vhd
    switch.vhd
    voter.vhd
    fir.vhd
    txt_util.vhd
}

foreach filename $rtl_files {

    set filepath [file join $SOURCE_DIR $filename]

    if {[file exists $filepath]} {

        puts "Adding: $filename"

        add_files \
            -fileset sources_1 \
            -norecurse \
            $filepath

    } else {

        puts "WARNING: File not found:"
        puts "  $filepath"
    }
}


# ============================================================
# Set RTL top
# ============================================================

puts ""
puts "Setting RTL top: $RTL_TOP"

set_property top $RTL_TOP [get_filesets sources_1]
set_property top_auto_set false [get_filesets sources_1]


# ============================================================
# Add constraints
# ============================================================

puts ""
puts "============================================================"
puts " Adding constraints"
puts "============================================================"

set constraint_file \
    [file join $CONSTRAINT_DIR "constraints.xdc"]

if {[file exists $constraint_file]} {

    puts "Adding: constraints.xdc"

    add_files \
        -fileset constrs_1 \
        -norecurse \
        $constraint_file

} else {

    puts "WARNING: Constraint file not found:"
    puts "  $constraint_file"
}


# ============================================================
# Add simulation sources
# ============================================================

puts ""
puts "============================================================"
puts " Adding simulation sources"
puts "============================================================"

set sim_files {
    fir_tb.vhd
}

foreach filename $sim_files {

    set filepath [file join $SIM_SOURCE_DIR $filename]

    if {[file exists $filepath]} {

        puts "Adding simulation file: $filename"

        add_files \
            -fileset sim_1 \
            -norecurse \
            $filepath

    } else {

        puts "WARNING: Simulation file not found:"
        puts "  $filepath"
    }
}


# ============================================================
# Set simulation top
# ============================================================

puts ""
puts "Setting simulation top: $SIM_TOP"

set_property top $SIM_TOP [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property top_auto_set false [get_filesets sim_1]


# ============================================================
# Add waveform configuration
# ============================================================

set WCFG_FILE \
    [file join $PROJECT_DIR "fir_tb_behav.wcfg"]

if {[file exists $WCFG_FILE]} {

    puts ""
    puts "Adding waveform configuration:"
    puts "  fir_tb_behav.wcfg"

    add_files \
        -fileset sim_1 \
        -norecurse \
        $WCFG_FILE

    set_property xsim.wcfg $WCFG_FILE [get_filesets sim_1]
}


# ============================================================
# Simulation settings
# ============================================================

puts ""
puts "Setting simulation options..."

set_property simulator_language VHDL [current_project]

set_property \
    xsim.simulate.runtime \
    "1000ns" \
    [get_filesets sim_1]


# ============================================================
# Update compile order
# ============================================================

puts ""
puts "Updating compile order..."

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1


# ============================================================
# Save project
# ============================================================

#mistake
puts ""
puts "Project created successfully."

# ============================================================
# Final information
# ============================================================

puts ""
puts "============================================================"
puts " Project successfully created"
puts "============================================================"
puts ""
puts "Project:"
puts "  $PROJECT_FILE"
puts ""
puts "Part:"
puts "  $FPGA_PART"
puts ""
puts "Board:"
puts "  $BOARD_PART"
puts ""
puts "RTL top:"
puts "  $RTL_TOP"
puts ""
puts "Simulation top:"
puts "  $SIM_TOP"
puts ""
puts "============================================================"
puts ""
