#include <filesystem>
#include <fstream>

namespace fs = std::filesystem;
long long getDuration(const fs::file_time_type & t1, const fs::file_time_type & t2);
void traversalDir(fs::path aPath, std::ofstream & outf, std::ofstream & fh);
