set pColl [get_ports *]
set pColl [remove_from_collection $pColl [get_ports clk]]
set pList []
foreach_in_collection p $pColl {
  #puts [get_object_name $p]
  #lappend pList [get_object $p]
  # get net
  set portConns [all_connected [all_connected $p]]
  foreach_in_collection pc $portConns {
    # Test is driven by a reg
    if {[get_attr $p direction] == "out" && [get_attr $pc object_class] == "pin" && [get_attr $pc direction] == "out" && [get_attr [get_cells -of_object $pc] is_sequential] == "false"} {
      puts [format "Output port %s is not driven by a register" [get_object_name $p]]
      puts [get_object_name $p]
      puts [get_object_name [get_cells -of_object $pc]]
      puts [get_attr [get_cells -of_object $pc] Ref_Name]
    } 
    if {[get_attr $p direction] == "in" && [get_attr $pc object_class] == "pin" && [get_attr $pc direction] == "in" && [get_attr [get_cells -of_object $pc] is_sequential] == "false"} {
      puts [format "Input port %s does not go to a register" [get_object_name $p]]
      puts [get_object_name $p]
      puts [get_object_name [get_cells -of_object $pc]]
      puts [get_attr [get_cells -of_object $pc] Ref_Name]
    } 
    
  }
  if {[sizeof_collection $portConns] > 2} {
    puts [format "Port %s connected to more than 1 cell" [get_object_name $p]]
    foreach_in_collection conn $portConns {
      puts [get_object_name $conn]
    }
  }
}
