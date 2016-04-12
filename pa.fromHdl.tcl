
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name myVGA_ -dir "C:/Users/ladyo/Documents/Xilinx/myVGA_/planAhead_run_3" -part xc6slx9tqg144-3
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "vga.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {ipcore_dir/clockManager.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {myVGA_.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top myVGA $srcset
add_files [list {vga.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx9tqg144-3
