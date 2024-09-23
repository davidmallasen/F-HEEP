#ifndef XHEEP_TB_UTIL_H
#define XHEEP_TB_UTIL_H

#include <iostream>

class XHEEP_CmdLineOptions // declare Calculator class
{

  public: // public members
    XHEEP_CmdLineOptions(int argc, char* argv[]); // default constructor

    std::string getCmdOption(int argc, char* argv[], const std::string& option); // get options from cmd lines
    bool get_use_openocd();
    std::string get_firmware();
    unsigned int get_max_sim_time(bool& run_all);
    unsigned int get_boot_sel();
    int argc;
    char** argv;

};



#endif
