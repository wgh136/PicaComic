import subprocess
import os

fontUse = '''
  fonts:
    - family: font
      fonts:
        - asset: fonts/NotoSansSC-Regular.ttf
'''

file = open('pubspec.yaml', 'r')
content = file.read()
file.close()
file = open('pubspec.yaml', 'a')
file.write(fontUse)
file.close()

subprocess.run(["flutter", "build", "windows"], shell=True)

file = open('pubspec.yaml', 'w')
file.write(content)

if os.path.exists("build/app-windows.zip"):
    os.remove("build/app-windows.zip")

version = str.split(str.split(content, 'version: ')[1], '+')[0]

# 压缩build/windows/x64/runner/Release, 生成app-windows.zip, 使用tar命令
subprocess.run(["tar", "-a", "-c", "-f", f"build/windows/PicaComic-{version}-windows.zip", "-C", "build/windows/x64/runner/Release", "."]
               , shell=True)

issContent = ""
file = open('windows/build.iss', 'r')
issContent = file.read()
newContent = issContent
newContent = newContent.replace("{{version}}", version)
newContent = newContent.replace("{{root_path}}", os.getcwd())
file.close()
file = open('windows/build.iss', 'w')
file.write(newContent)
file.close()

subprocess.run(["iscc", "windows/build.iss"], shell=True)

with open('windows/build.iss', 'w') as file:
    file.write(issContent)