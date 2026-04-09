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

static void recordDenied(const fs::path & p, std::ofstream & fh) {
	fh << p << '\n';
}

//fs namespace defined in header file.
void traversalDir(const fs::path & aPath, std::ofstream & outf, std::ofstream & fh) {
	std::error_code ec;
	if (!fs::exists(aPath, ec) || ec) {
		std::cerr << "Input path does not exist: " << aPath << std::endl;
		recordDenied(aPath, fh);
		return;
	}
	if (!fs::is_directory(aPath, ec) || ec) {
		std::cerr << "Input path is not a directory: " << aPath << std::endl;
		recordDenied(aPath, fh);
		return;
	}

	fs::recursive_directory_iterator it(aPath, fs::directory_options::skip_permission_denied, ec);
	if (ec) {
		std::cerr << "Cannot open directory: " << aPath << " ; " << ec.message() << std::endl;
		recordDenied(aPath, fh);
		return;
	}
	fs::recursive_directory_iterator end;
	using fs::perms;
	while(it != end){
		const fs::path currentPath = it->path();
		try{
			std::error_code sec;
			const fs::file_status status = it->symlink_status(sec);
			if (sec) {
				std::cerr << "Failed to read status: " << currentPath << " ; " << sec.message() << std::endl;
				recordDenied(currentPath, fh);
				sec.clear();
				it.increment(sec);
				if (sec) {
					std::cerr << "Iterator increment failed: " << currentPath << " ; " << sec.message() << std::endl;
				}
				continue;
			}

			const perms p = status.permissions();
			gid_t my_gid = getgid();
			struct stat file_stat;
			if (fs::is_directory(status)){
				if (stat(currentPath.c_str(), &file_stat) == 0){
					if (my_gid == file_stat.st_gid){
						if ((perms::none == (perms::group_read & p)) && (perms::none == (perms::group_exec & p))) {
							recordDenied(currentPath, fh);
						}
					}else{
						if ((perms::none == (perms::others_read & p)) && (perms::none == (perms::others_exec & p))) {
							recordDenied(currentPath, fh);
						}
					}
				}else {
					std::cerr << "Fail to get entry's gid: " << currentPath << std::endl;
					recordDenied(currentPath, fh);
				}
			}

			if (fs::is_symlink(status)){
				std::error_code incEc;
				it.increment(incEc);
				if (incEc) {
					std::cerr << "Iterator increment failed: " << currentPath << " ; " << incEc.message() << std::endl;
					recordDenied(currentPath, fh);
				}
				continue;
			}

			if (fs::is_regular_file(status)){
				std::error_code metaEc;
				const auto fileSize = it->file_size(metaEc);
				if (metaEc) {
					std::cerr << "Failed to read file size: " << currentPath << " ; " << metaEc.message() << std::endl;
					recordDenied(currentPath, fh);
				} else {
					const auto lastWriteTime = it->last_write_time(metaEc);
					if (metaEc) {
						std::cerr << "Failed to read mtime: " << currentPath << " ; " << metaEc.message() << std::endl;
						recordDenied(currentPath, fh);
					} else {
						const long long secondsDiff = getDuration(lastWriteTime, fs::file_time_type::clock::now());
						const long long daysDiff = secondsDiff / (24 * 60 * 60);
						outf << currentPath << "\t"
							<< HumanReadable{fileSize} << "\t"
							<< secondsDiff << "\t"
							<< daysDiff << std::endl;
					}
				}
			}

			std::error_code incEc;
			it.increment(incEc);
			if (incEc) {
				std::cerr << "Iterator increment failed: " << currentPath << " ; " << incEc.message() << std::endl;
				recordDenied(currentPath, fh);
			}
		} catch (const fs::filesystem_error & err){
			std::cerr << err.what() << std::endl;
			if (!currentPath.empty()) {
				recordDenied(currentPath, fh);
			}
			std::error_code rc;
			it.increment(rc);
			if (rc && !currentPath.empty()) {
				recordDenied(currentPath, fh);
			}
		} catch (const std::exception & err) {
			std::cerr << "Unexpected error on path " << currentPath << " : " << err.what() << std::endl;
			if (!currentPath.empty()) {
				recordDenied(currentPath, fh);
			}
			std::error_code rc;
			it.increment(rc);
			if (rc && !currentPath.empty()) {
				recordDenied(currentPath, fh);
			}
		} catch (...) {
			std::cerr << "Unknown error on path " << currentPath << std::endl;
			if (!currentPath.empty()) {
				recordDenied(currentPath, fh);
			}
			std::error_code rc;
			it.increment(rc);
			if (rc && !currentPath.empty()) {
				recordDenied(currentPath, fh);
			}
		}
	}
}
