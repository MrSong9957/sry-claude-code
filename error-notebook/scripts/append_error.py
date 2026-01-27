import datetime
import sys
import re
import os
import glob


def get_project_name():
    """
    从当前工作目录路径中提取项目名
    
    返回:
        str: 项目名
    """
    # 获取当前工作目录
    current_dir = os.getcwd()
    # 从路径中提取最后一个目录名作为项目名
    project_name = os.path.basename(current_dir)
    # 转换为小写并去除特殊字符，确保文件名安全
    project_name = re.sub(r'[^a-zA-Z0-9_-]', '-', project_name.lower())
    return project_name


def count_records(file_path):
    """
    统计文档中的错误记录数
    
    参数:
        file_path (str): 文档文件路径
    
    返回:
        int: 错误记录数
    """
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            # 计算以 "## " 开头的行，这些是错误记录的时间戳
            lines = content.split('\n')
            count = 0
            for line in lines:
                if line.strip().startswith('## '):
                    count += 1
            return count
    except FileNotFoundError:
        return 0


def get_current_file(project_name):
    """
    获取当前应该使用的错误笔记本文档
    
    参数:
        project_name (str): 项目名
    
    返回:
        str: 当前应该使用的文档文件路径
    """
    # 主文档路径
    main_file = f"docs/error-notebook-{project_name}.md"
    
    # 检查主文档是否存在
    if not os.path.exists(main_file):
        # 创建主文档目录
        os.makedirs(os.path.dirname(main_file), exist_ok=True)
        # 创建主文档
        with open(main_file, "w", encoding="utf-8") as f:
            f.write("# 错误笔记本\n\n")
        return main_file
    
    # 统计主文档中的记录数
    record_count = count_records(main_file)
    
    # 如果记录数超过100，查找或创建新的编号文档
    if record_count >= 100:
        # 查找现有的编号文档
        pattern = f"docs/error-notebook-{project_name}-*.md"
        existing_files = glob.glob(pattern)
        
        if existing_files:
            # 提取最大编号
            max_num = 0
            for file in existing_files:
                match = re.search(rf'error-notebook-{project_name}-(\d+)\.md', file)
                if match:
                    num = int(match.group(1))
                    if num > max_num:
                        max_num = num
            
            # 检查最新的编号文档
            current_file = f"docs/error-notebook-{project_name}-{max_num}.md"
            current_count = count_records(current_file)
            
            # 如果最新的编号文档也超过100条记录，创建新的
            if current_count >= 100:
                new_num = max_num + 1
                new_file = f"docs/error-notebook-{project_name}-{new_num}.md"
                with open(new_file, "w", encoding="utf-8") as f:
                    f.write("# 错误笔记本\n\n")
                return new_file
            else:
                return current_file
        else:
            # 创建第一个编号文档
            new_file = f"docs/error-notebook-{project_name}-1.md"
            with open(new_file, "w", encoding="utf-8") as f:
                f.write("# 错误笔记本\n\n")
            return new_file
    else:
        return main_file


def get_modification_count(error_type, fragment, file_path="docs/error-notebook.md"):
    """
    获取错误的修改次数
    
    参数:
        error_type (str): 错误类型
        fragment (str): 错误片段（用于匹配）
        file_path (str): 日志文件路径
    
    返回:
        int: 修改次数
    """
    try:
        # 提取项目名
        project_name = get_project_name()
        # 构建文件模式
        pattern = f"docs/error-notebook-{project_name}*.md"
        # 查找所有相关文件
        files = glob.glob(pattern)
        
        # 如果没有找到相关文件，检查主文件
        if not files:
            files = [file_path]
        
        # 计算匹配到的次数
        total_count = 0
        
        for file in files:
            try:
                with open(file, "r", encoding="utf-8") as f:
                    content = f.read()
                    lines = content.split('\n')
                    
                    # 遍历每一行，查找匹配的错误类型和片段
                    for i, line in enumerate(lines):
                        # 查找错误类型行
                        if f"[错误类型] {error_type}" in line:
                            # 查找片段行
                            for j in range(i+1, min(i+5, len(lines))):
                                if f"片段: \"{fragment}\"" in lines[j]:
                                    # 检查是否是完整的错误条目
                                    for k in range(max(0, i-5), i):
                                        if lines[k].startswith('## '):
                                            total_count += 1
                                            break
                                    break
            except FileNotFoundError:
                continue
        
        return total_count
    except Exception:
        return 0


def append_error(error_type, fragment, description, suggestion, task_background="", file_path=None, failed_attempts=[], successful_method=""):
    """
    将错误条目追加到错误笔记本
    
    参数:
        error_type (str): 错误类型 (推理/技术/表述/环境)
        fragment (str): 对话片段
        description (str): 错误描述
        suggestion (str): 改进建议
        task_background (str): 任务背景，包含用户输入和AI IDE执行情况
        file_path (str): 日志文件路径，默认自动根据项目名确定
        failed_attempts (list): 失败的尝试操作列表
        successful_method (str): 成功修改的方法
    """
    # 获取项目名
    project_name = get_project_name()
    
    # 确定目标文档
    if file_path is None:
        file_path = get_current_file(project_name)
    
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # 构建基本错误内容
    base_content = f"""- [错误类型] {error_type}  
  片段: "{fragment}"  
  描述: {description}  
  改进建议: {suggestion}  
  任务背景: {task_background}  """
    
    # 检查修改次数
    modification_count = get_modification_count(error_type, fragment, file_path)
    is_persistent = modification_count >= 3
    
    # 根据是否是顽疾构建不同的条目内容
    if is_persistent:
        # 顽疾的详细记录
        entry_content = f"""- [错误类型] {error_type} [顽疾]  
  片段: "{fragment}"  
  描述: {description}  
  改进建议: {suggestion}  
  任务背景: {task_background}  
  修改次数: {modification_count + 1}  
  失败的尝试: {" | ".join(failed_attempts) if failed_attempts else "无详细记录"}  
  成功方法: {successful_method if successful_method else "无详细记录"}  """
    else:
        # 普通错误的记录
        entry_content = base_content
    
    # 检查是否存在重复条目
    duplicate_found = False
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            # 检查是否包含相同的错误内容（忽略时间戳）
            if entry_content.strip() in content:
                duplicate_found = True
    except FileNotFoundError:
        # 文件不存在，创建新文件
        pass
    
    if not duplicate_found:
        entry = f"""
## {timestamp}
{entry_content}
"""
        with open(file_path, "a+", encoding="utf-8") as f:
            f.write(entry.strip() + "\n")

# 命令行接口
if __name__ == "__main__":
    # 打印调试信息
    print("当前工作目录:", os.getcwd())
    print("项目名:", get_project_name())
    
    if len(sys.argv) >= 5:
        error_type = sys.argv[1]
        fragment = sys.argv[2]
        description = sys.argv[3]
        suggestion = sys.argv[4]
        
        # 处理可选参数
        task_background = sys.argv[5] if len(sys.argv) > 5 else ""
        failed_attempts = sys.argv[6].split('|') if len(sys.argv) > 6 else []
        successful_method = sys.argv[7] if len(sys.argv) > 7 else ""
        
        append_error(
            error_type=error_type,
            fragment=fragment,
            description=description,
            suggestion=suggestion,
            task_background=task_background,
            failed_attempts=failed_attempts,
            successful_method=successful_method
        )
    else:
        # 示例调用（必须在任务结束时执行）
        print("执行示例调用...")
        append_error(
            error_type="技术错误",
            fragment="遗漏了文件追加逻辑",
            description="没有说明如何使用追加模式",
            suggestion="使用 a+ 模式写入文件",
            task_background="用户要求实现文件追加功能，但代码中缺少具体实现逻辑"
        )
        print("示例调用完成")