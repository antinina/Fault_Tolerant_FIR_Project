restart
add_force {/fir_tb/uut/\other_sections(7)\/fir_section/mac_out_s[2]} -radix hex {0 690ns}
add_force {/fir_tb/uut/\other_sections(7)\/fir_section/mac_out_s[1]} -radix hex {0 780ns}
add_force {/fir_tb/uut/\other_sections(7)\/fir_section/mac_out_s[0]} -radix hex {0 860ns}
add_force {/fir_tb/uut/\other_sections(7)\/fir_section/mac_out_s[3]} -radix hex {0 990ns}
run 1100ns
