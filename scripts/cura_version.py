import json
import sys
import subprocess

def get_commit_hash(project, cmake_binary_dir):
    project_path = cmake_binary_dir + "/" + project + "-prefix/src/" + project
    result = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=project_path)
    return result.decode("utf-8").replace('\n', '')

def get_curabuild_commit_hash(cmake_binary_dir):
    project_path = cmake_binary_dir + "/.."
    result = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=project_path)
    return result.decode("utf-8").replace('\n', '')

def generate(cura_version, cmake_binary_dir, target_dir):
    data = {
        "cura_version": cura_version,
	"cura": get_commit_hash("Cura", cmake_binary_dir),
        "uranium": get_commit_hash("Uranium", cmake_binary_dir),
        "engine": get_commit_hash("CuraEngine", cmake_binary_dir),
        "libarcus": get_commit_hash("Arcus", cmake_binary_dir),
        "binarydata":get_commit_hash("cura-binary-data", cmake_binary_dir),
	"build": get_curabuild_commit_hash(cmake_binary_dir)
    }

    with open(target_dir + "/version.json", 'w') as output_file:
        output_file.write(json.dumps(data, indent=4))
    
    with open(cmake_binary_dir + "/CURA2_VERSION", 'w') as text_file:
        print("{}".format(cura_version), file=text_file)

if __name__ == '__main__':
    generate(sys.argv[1], sys.argv[2], sys.argv[3])
