# Skill nào từ `mattpocock/skills` đáng đưa vào SimplifyKit

**Ngày:** 2026-10-07 · **Nguồn:** `mattpocock/skills` (commit `6fd9479`, MIT), đọc tại `D:\git-repo\mattpocock-skills\skills\skills` · **Đối chiếu với:** SimplifyKit 0.3.0, `plugins/sk/reference/playbook-mapping.md`

## Câu hỏi

Trong khoảng 40 skill của repo đó, skill nào giúp team làm việc theo AI-SDLC playbook hiệu quả hơn, mà vẫn giữ được các ràng buộc của kit: chỉ chạy trên Claude Code, ADO chỉ đọc, chỉ dùng markdown, và mỗi stage để lại một artifact?

## Cách đánh giá

Mỗi skill được xét theo ba điều kiện:

1. Nó có lấp một stage mà `playbook-mapping.md` ghi là còn thiếu không.
2. Nó có cần ghi lên tracker không. Nếu cần thì loại, vì ADO trong kit chỉ được đọc.
3. Nó có làm việc trên artifact `sk/` không. Nếu không, team cài thẳng plugin gốc là đủ, không cần chuyển thể.

## Những gì kit đã lấy từ repo này

| Skill gốc | Đang nằm ở đâu trong kit |
|---|---|
| `grilling` (hỏi theo vòng frontier, mỗi câu có đáp án đề xuất) | Step 4 của `/sk:propose` (câu hỏi đánh số `G1`, `G2`…) |
| `domain-modeling` (3 tiêu chí của ADR, format glossary) | Bước ghi bản ghi của `/sk:archive` → `sk/adr/`, `sk/context.md` |

## Nhóm 1: tích hợp

| Skill gốc | Đưa vào kit thành | Trạng thái |
|---|---|---|
| `code-review` (Standards + Spec, neo vào fixed point, kiểm scope creep) | `/sk:verify`, khung lấy từ OpenSpec `openspec-verify-change` | **Đã làm ở 0.4.0** |
| `tdd` (red → green tại seam đã thống nhất, slice dọc, không viết test kiểu tautology) | `reference/tdd.md` cộng một bước trong `/sk:apply`: mỗi `#### Scenario` là một seam, viết test fail trước rồi mới implement | Việc tiếp theo. Có đụng `/sk:apply`, nên phải chạy lại `apply-implements-tasks` |
| `pr` (Summary dạng hình nhỏ nhất, Evidence before/after, Merge Danger: one-way/two-way door + blast radius) | `/sk:pr` chỉ sinh nội dung PR body, có link AB#, delta và tiến độ tasks | Việc tiếp theo. **Không tạo PR trên ADO**, vì đó là một thao tác ghi |

## Nhóm 2: có giá trị, làm sau

- **`to-questionnaire`**: chuyển Gaps và Open questions thành một file câu hỏi gửi PO/BA. `/sk:continue` hiện chỉ in một danh sách để paste vào comment.
- **`diagnosing-bugs`**: luồng cho work item loại Bug (dựng feedback loop đỏ → thu nhỏ repro → hypothesis → regression test). Kit hiện thiên về User Story.
- **`retro`**: sau mỗi change, đề xuất bổ sung `sk/config.yaml` → `rules`, hoặc một check tự động, cho lỗi vừa gặp. Việc này đóng vòng Stage 6.
- **"Blocked by" của `to-tickets`** áp vào `tasks.md`: đây là thay đổi thiết kế. `/sk:apply` hiện lấy chuyện `tasks.md` không có dependency graph làm lý do để không chặn ở open question. Nếu thêm edge, lý do đó phải viết lại. Nếu làm, `implement-spec` (chạy song song nhiều worktree) mới có chỗ dùng.

## Nhóm 3: không tích hợp

| Skill | Lý do |
|---|---|
| `to-spec`, `to-tickets`, `triage`, `wayfinder` | Publish issue, label hoặc comment lên tracker, mâu thuẫn với luật ADO read-only. Vai trò của `to-spec` đã nằm ở `/sk:propose` + `/sk:continue` |
| `setup-matt-pocock-skills`, `ask-matt` | `/sk:init` và 6 lệnh của kit đã bao phần này |
| `prototype`, `wizard`, `improve-codebase-architecture`, `codebase-design`, `teach`, `grill-me`, `wait-what`, nhóm `misc`, nhóm `in-progress` | Công cụ chung, không làm trên artifact `sk/`. Ai cần thì cài plugin `mattpocock-skills` |
| `writing-for-agents` | Hữu ích cho **người bảo trì repo này** khi viết SKILL.md, nhưng không phải thứ người dùng kit cần |
| `handoff` | State của kit đã nằm trên đĩa và được commit (`sk/changes/<id>/`), nên đồng đội nhận việc chỉ cần đọc thư mục đó |

## Rủi ro khi cài song song hai plugin

`domain-modeling` của Matt ghi `GLOSSARY.md` và `docs/adr/`, còn kit ghi `sk/context.md` và `sk/adr/`. Nếu cài cả hai, một repo sẽ có hai bộ glossary và ADR tách nhau, và agent không biết bộ nào là chuẩn. Đó là lý do skill thuộc Nhóm 1 được **chuyển thể** để đọc và ghi artifact `sk/`, chứ không khuyên team cài plugin gốc song song.

Hai tên lệnh cũng có thể đụng nhau: `code-review` đã có sẵn như built-in skill trong một số môi trường. Lệnh của kit có namespace (`/sk:verify`), nên không bị đụng.
