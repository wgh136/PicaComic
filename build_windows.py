import subprocess
import os

fontUse = '''
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

# 压缩build/windows/x64/runner/Release, 生成app-windows.zip, 使用tar命令
subprocess.run(["tar", "-a", "-c", "-f", "build/app-windows.zip", "-C", "build/windows/x64/runner/Release", "."]
               , shell=True)
