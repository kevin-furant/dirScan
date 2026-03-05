#include <cstdio>
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
	std::ofstream fh(outPermissionDeniedFile, std::ios::app);	
	fs::path searchPath(path);
	traversalDir(searchPath, outf, fh);
	outf.close();
	fh.close();
	return 0;
}
