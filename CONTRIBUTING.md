# Sửa chính bộ kit

Dành cho người bảo trì SimplifyKit. Người dùng kit thì đọc `README.md`.

## Cấu trúc

```
.claude-plugin/marketplace.json     khai báo marketplace `simplify`
plugins/sk/
  .claude-plugin/plugin.json        manifest: tên, version, mô tả
  skills/{init,propose,apply,archive}/SKILL.md
  templates/                        khung file mà skill copy vào repo người dùng
  reference/                        tài liệu skill đọc lúc chạy
  evals/                            bộ test hành vi
```

Skill trỏ tới reference và template bằng `${CLAUDE_PLUGIN_ROOT}/...`. **Đừng dùng đường dẫn tương đối** — một lần chạy thật cho thấy model resolve `reference/conventions.md` thành `skills/propose/reference/conventions.md` và không đọc được gì, trong khi kết quả nhìn vẫn có vẻ đúng.

## Sửa xong không thấy tác dụng?

Bản đã cài là **copy trong cache, khoá theo version**:

```
~/.claude/plugins/cache/simplify/sk/<version>/
```

Sửa file trong repo không chạm tới bản đó. Phải:

1. Tăng `version` trong `plugins/sk/.claude-plugin/plugin.json`
2. `claude plugin update sk@simplify`
3. Phiên Claude Code mới mới nạp bản mới

Bỏ bước này thì mọi phép kiểm sau đó đều đang đo bản cũ — và sẽ báo "đã sửa xong" một cách thuyết phục.

## Chạy eval

```bash
cd plugins/sk

# lặp nhanh một case, một nhánh
claude plugin eval . --case propose-from-work-item --runs 1 --ablation none \
  --allow-tools Write Edit --scaffold

# chạy đủ, có nhánh không-plugin để so sánh
claude plugin eval . --allow-tools Write Edit --scaffold --no-publish
```

**Windows: Git Bash phải đứng trước WSL trong PATH.** Không thì mọi case đều 0 điểm với `scaffold failed (exit 1)`, vì `bash` mặc định là của WSL và không có `/bin/bash`:

```powershell
$env:PATH = "C:\Program Files\Git\bin;" + $env:PATH
```

Ngưỡng chia theo nhóm vì số grader khác nhau — chi tiết và các bẫy khi viết grader nằm trong `plugins/sk/evals/README.md`.

### Eval không đo được gì

Hai vùng, đều phải kiểm tay:

- **Đường gọi Azure DevOps** — mỗi run eval không có Bash, nên không gọi `az` được
- **Cạnh tranh skill** — mỗi run chỉ nạp đúng plugin này, nên Claude thấy 4 skill. Trong repo thật nó có thể thấy gần trăm skill với mô tả bị cắt ngắn

Cả hai đã được kiểm bằng một đợt pilot trên repo thật: chạy hết vòng `init → propose` với work item thật, và đo việc chọn skill trong hai môi trường chỉ khác nhau một biến (có và không có rule định tuyến) — `sk:propose` thắng cả hai lần. Khi thêm skill mới, hai vùng này vẫn phải kiểm tay như vậy.

## Vì sao đọc work item qua REST chứ không qua `az`

Đo trên một work item thật, acceptance criteria có dấu gạch ngang dài:

| Đường lấy | Ký tự hỏng (U+FFFD) | Em dash thật | Đọc comment |
|---|---|---|---|
| `az boards work-item show --expand all` | 9 | 0 | — |
| `az devops invoke ... comments` | — | — | lỗi `TypeError` |
| REST + access token | **0** | **9** | **được** |

`az` làm hỏng ký tự non-ASCII ngay từ lúc ghi ra, nên `chcp 65001`, `PYTHONIOENCODING`, `PYTHONUTF8`, `Console.OutputEncoding` đều vô ích — đã thử cả bốn. Một pilot thật đã để 4 ký tự `?` lọt vào file đặc tả cuối cùng trước khi phát hiện.

`az devops invoke --area wit --resource comments` thì hỏng hẳn với lỗi nội bộ của extension, tái hiện trên mọi work item — nghĩa là bước đọc comment chưa từng chạy được lần nào cho tới khi chuyển sang REST.

`az` vẫn được dùng cho hai việc nó làm đúng: `az devops configure --list` và `az account get-access-token`.

`propose` có một cổng chặn: quét U+FFFD sau khi bóc HTML, còn ký tự hỏng thì dừng, không ghi spec. Cổng này cũng bắt được nếu sau này ai đó quay lại dùng `az boards` vì nó trông gọn hơn.

## Fixture đi theo bản cài của mọi người

`evals/` **được đóng gói cùng plugin**. Teammate chạy `/plugin install` là tải về cả bộ eval — đo được: 425 KB, 59 file trong `~/.claude/plugins/cache/simplify/sk/<version>/evals/`.

Không tránh được nếu còn muốn dùng `claude plugin eval`: công cụ chỉ nhận eval dir nằm **dưới thư mục plugin**, cả qua cờ `--eval-dir` lẫn `experimental.evals` trong manifest.

Về chi phí thì không đáng kể — eval không phải skill hay command nên Claude không đọc chúng, không tốn token nào. Nhưng về dữ liệu thì đáng kể:

**Payload work item nằm trong heredoc bên trong `plugins/sk/evals/**/fixture.sh`** — không có file `.json` fixture độc lập nào, nên `grep` theo `*.json` sẽ trả về rỗng và không chứng minh được gì. Chúng giữ nguyên *cấu trúc HTML* của work item thật, đó là giá trị của chúng; còn tên sản phẩm, tên khách hàng, org URL và mã work item đều đã thay bằng dữ liệu bịa.

Mỗi bản cài là một bản sao trên một máy khác, nên **mốc rà lại là trước khi ai đó cài**, không phải trước khi push. Thêm fixture mới thì rà lại từ đầu; checklist nằm trong `CHANGELOG.md`.

## Quy ước khi viết skill

- Mỗi `SKILL.md` có `name` khớp đúng tên thư mục — đó là thứ quyết định lệnh ra `/sk:<tên>`
- `description` mở đầu bằng "SimplifyKit (sk):" và nêu rõ khi nào dùng; đây là thứ quyết định skill có được chọn hay không khi người dùng không gõ tên lệnh
- Giữ `SKILL.md` đủ ngắn để nạp nhanh; chi tiết dài đẩy sang `reference/`
- Quy tắc nào đến từ một lỗi thật thì ghi kèm lý do. Chỉ dẫn không có lý do sẽ bị người sau tối giản đi mất
