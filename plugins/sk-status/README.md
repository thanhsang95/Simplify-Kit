# sk-status

Plugin phụ của SimplifyKit: cho biết mỗi change trong `sk/changes/` đang ở đâu và lệnh `/sk:*` tiếp theo là gì. `sk` không phụ thuộc vào nó. Gỡ nó ra thì kit vẫn chạy y như cũ.

```
/plugin install sk-status@simplify
```

Đã thử trên Claude Code 2.1.286. Đây là một [mod](https://code.claude.com/docs/en/plugins/mods/overview), mà API của mod còn ở giai đoạn early access và có thể đổi giữa các bản. Nếu module không load được, transcript hiện một dòng mờ `sk-status: …` và các lệnh `/sk:*` vẫn chạy bình thường.

## Hiển thị gì

| Ở đâu | Nội dung |
| --- | --- |
| Status line | `sk <id> · <bước> · ▲ Q<n> · ⇥ <lệnh tiếp theo>` của change sửa gần nhất |
| Ô prompt | Sau mỗi lượt, lệnh tiếp theo hiện mờ; Tab để lấy |
| `/sk-status` | Bảng: danh sách change, pipeline, đọc file, chạy lệnh |

Phím trong bảng `/sk-status`:

| Phím | Làm gì |
| --- | --- |
| `1`–`9` | Chọn change (khi có từ 2 change) |
| `o` | Đổi thứ tự: sửa gần nhất ↔ gần archive nhất |
| `p` `s` `d` `t` | Đọc `proposal.md`, spec delta, `design.md`, `tasks.md` ngay trong bảng; `b` quay lại |
| `n` | Chạy lệnh tiếp theo |
| `a` | `/sk:archive`: hiện hộp xác nhận, bấm `a` lần nữa mới chạy, `c` huỷ |
| `e` | Điền lệnh tiếp theo vào ô prompt để sửa trước khi chạy |
| Esc | Đóng bảng |

## Cách nó suy ra trạng thái

Không có status CLI. Trạng thái được đọc từ file trên đĩa, giống cách các skill tự làm:

- Thứ tự artifact và điều kiện "xong" lấy theo `/sk:continue` Step 2. `design.md` được tính là xong khi file tồn tại, hoặc khi `proposal.md` có `## Design` ghi đã skip
- `**AC source:** none yet` → bước tiếp theo là `/sk:propose <id>`
- Checkbox trong `tasks.md` đếm theo luật của `/sk:verify`: chỉ ô chứa `x`/`X` mới tính là xong
- Open question là các token `[[OPEN:Q<n>]]` trong spec delta (`reference/conventions.md`)
- Bỏ qua `sk/changes/archive/`. Tự quét lại mỗi 4 giây và sau mỗi lượt; chỉ vẽ lại khi có thay đổi

Đổi một trong các luật trên trong skill `sk` thì phải sửa `hooks/register.tsx` cho khớp. Không có test nào bắt được sự lệch này.

## Giới hạn

- Chỉ đọc. Không ghi file, không gọi Azure DevOps, không tự chạy lệnh
- `/sk:verify` không ghi file nào, nên bảng không biết một change đã verify hay chưa. Khi mọi task đã tick, bảng luôn đề xuất verify rồi mới archive
- Nếu không tìm được lệnh của plugin `sk` (chưa cài, hoặc đang tắt), nút chạy lệnh chỉ điền lệnh vào ô prompt
