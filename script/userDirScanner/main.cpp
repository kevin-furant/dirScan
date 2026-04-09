#include <cstdio>
#include <iostream>
#include <stdexcept>
#include "userDirScanner.h"

static void usage(char *argv[]){
	std::printf("Usage: %s <userDir> <outTsv>\n", argv[0]);
}

int main(int argc, char * argv[]){
	if (argc < 3){
		usage(argv);
		exit(EXIT_FAILURE);
	}
	char * path = argv[1];
	char * outTsv = argv[2];
        fs::path outTsvPath(outTsv);
        fs::path outPermissionDeniedFile = outTsvPath.parent_path() / (outTsvPath.stem().string() + ".permission_denied.tsv");
	std::ofstream outf(outTsv, std::ios::out);
	if (!outf.is_open()) {
		std::cerr << "Cannot open output file: " << outTsv << std::endl;
		return 0;
	}
	std::ofstream fh(outPermissionDeniedFile, std::ios::app);
	if (!fh.is_open()) {
		std::cerr << "Cannot open permission denied file: " << outPermissionDeniedFile << std::endl;
		return 0;
	}
	fs::path searchPath(path);
	try {
		traversalDir(searchPath, outf, fh);
	} catch (const std::exception & e) {
		std::cerr << "Fatal scan error: " << e.what() << std::endl;
		fh << searchPath << '\n';
	} catch (...) {
		std::cerr << "Unknown fatal scan error." << std::endl;
		fh << searchPath << '\n';
	}
	outf.close();
	fh.close();
	return 0;
}
