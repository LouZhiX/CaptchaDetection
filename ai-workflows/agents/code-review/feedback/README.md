# 本目录用于存放待人工审核的反馈（/err /miss /ex）。
# 文件格式：<ts>-mr<id>.jsonl，一行一条反馈。
#
# 由 webhook-server 的 /webhook/feedback 写入；由 cron 定时任务消费并清理（移动到 archived/）。
