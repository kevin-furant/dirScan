#include <iostream>
#include <cstdint>
#include <cmath>
#include <chrono>
#include <system_error>
#include <sys/stat.h>
#include <unistd.h>
#include "userDirScanner.h"

struct HumanReadable
{
    std::uintmax_t size{};
 
    template<typename Os> friend Os& operator<<(Os& os, HumanReadable hr)
    {
        int i{};
        double mantissa = hr.size;
        for (; mantissa >= 1024.0; mantissa /= 1024.0, ++i)
        {}
        os << std::ceil(mantissa * 10.0) / 10.0 << i["BKMGTPE"];
        return i ? os << "B (" << hr.size << ')' : os;
    }
};

long long getDuration(const fs::file_time_type & t1, const fs::file_time_type & t2){
	auto duration  = t2 - t1;
	auto seconds = std::chrono::duration_cast<std::chrono::seconds>(duration).count();
	return seconds > 0 ? seconds : 0;
}
//fs namespace defined in header file.
void traversalDir(fs::path aPath, std::ofstream & outf, std::ofstream & fh) {
	fs::recursive_directory_iterator it(aPath, fs::directory_options::skip_permission_denied);
	fs::recursive_directory_iterator end = fs::end(it);
	using fs::perms;
	while(it != end){
		try{
			//if (it->is_symlink()) continue;
			perms p = fs::status(*it).permissions();
			gid_t my_gid = getgid();
			struct stat file_stat;
			if (it->is_directory()){
				if (stat(it->path().c_str(), &file_stat) == 0){
					if (my_gid == file_stat.st_gid){
						//in same group
						if ((perms::none == (perms::group_read & p)) && (perms::none == (perms::group_exec & p))) {
							fh << it->path() << std::endl;
						}
					}else{
						//not in same group
						if ((perms::none == (perms::others_read & p)) && (perms::none == (perms::others_exec & p))) {
							fh << it->path() << std::endl;
						}
					}
				}else {
					std::cerr << "Fail to get entry's gid: " << it->path() << std::endl;					
				}
			}
			if (it ->is_symlink()){
				++it;
				continue;
			}
			if (it->is_regular_file()){
				//if (perms::none == (perms::group_read & p)){
				//	fh << it->path() << std::endl;
				//}else {
				const auto lastWriteTime = fs::last_write_time(*it);
				const long long secondsDiff = getDuration(lastWriteTime, fs::file_time_type::clock::now());
				const long long daysDiff = secondsDiff / (24 * 60 * 60);
				outf << it->path() << "\t"
					<< HumanReadable{it->file_size()} << "\t"
					<< secondsDiff << "\t"
					<< daysDiff << std::endl;
				//}
			}
			++it;
		} catch (const fs::filesystem_error & err){
			std::cerr << err.what() << std::endl;
			//fh << err.path1() << std::endl;
			std::error_code rc;
			it.increment(rc);
		}
	}
}
