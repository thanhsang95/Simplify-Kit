# Kế hoạch triển khai cải tiến Simplify Kit (sk)

Nov 10, 2026 · @sang

## Mục tiêu và phạm vi

Mục tiêu: giảm thời gian con người trên mỗi thay đổi mà không tăng số lỗi lọt qua, bằng cách đưa phần lớn việc review vào trước khi PR được tạo. Kế hoạch áp dụng các ý từ bài "How the Claude Code team does code review" (claude.dev, 15/10/2026) vào Simplify Kit v0.11.0.

Bối cảnh team:

- Dùng Azure DevOps; Azure Pipelines không chạy Claude Code, nên mọi review bằng Claude diễn ra trên máy cá nhân.
- Review hai lần: tác giả tự review trước khi tạo PR, sau đó hai dev khác review PR (kéo code về máy khi cần).
- Kit đọc ADO nhưng không bao giờ ghi lên ADO.

Phạm vi: các skill `propose`, `pr`, `verify`, `init`, `archive`, thư mục `reference/`, `templates/`, `evals/` và README. Một skill mới `/sk:learn` ở giai đoạn cuối. Cấu hình Azure DevOps và quy ước team nằm ngoài kit nhưng được liệt kê để triển khai cùng.

## Nguyên tắc thiết kế cần giữ nguyên

Mọi thay đổi trong kế hoạch phải giữ được năm nguyên tắc hiện có của kit. Thay đổi nào phá một nguyên tắc thì phải được thảo luận riêng trước khi làm.

1. **ADO chỉ đọc.** Kit không tạo PR, không comment, không đổi trạng thái work item. Kit xuất văn bản, người dùng dán.
2. **`verify` chỉ đọc.** Không sửa code, không tạo file, không tick task. Các grader `no-file-created-in-sk`, `no-edit-outside-sk` tiếp tục phải pass.
3. **Dừng lại hỏi thay vì đoán.** Mọi chế độ mới đều thông báo lựa chọn của mình và cách đổi (giống `Using change: <id>`).
4. **Chỉ nói điều artifact hoặc cuộc trò chuyện thực sự cho thấy.** Không bịa kết quả test, reviewer, hay con số.
5. **Một định nghĩa, một nơi.** Quy tắc dùng chung (checkbox, marker câu hỏi mở, tiêu chí rủi ro) nằm trong `reference/conventions.md`, các skill tham chiếu tới đó.

## Tổng quan các giai đoạn

Bốn giai đoạn chạy nối tiếp, mỗi giai đoạn là một bản phát hành và chỉ ra khi qua cổng của nó. Cấu hình ADO và quy ước team làm song song ngay từ đầu.

&#91;embedded content: lộ trình · 4 giai đoạn, 3 cổng\]

Giai đoạn 2 và 3 đều dùng tiêu chí rủi ro và mã phát hiện của giai đoạn 1. Giai đoạn 4 cần ít nhất một tháng comment và trạng thái thread thật từ giai đoạn 1–3.

## Giai đoạn 1 — Nền tảng

Giai đoạn này tạo các định nghĩa dùng chung mà ba giai đoạn sau dựa vào. Các thay đổi nhỏ, ít rủi ro, phát hành thành bản **v0.13.0** (0.12.0 đã dùng cho bản rút gọn chữ).

> **Trạng thái (2026-11-10): đã triển khai** trên nhánh `feat/sk-shared-risk-and-finding-ids`. Khác với bản thảo:
> - Nhãn báo cáo dùng tiếng Anh ASCII (`fixed` / `wrong` / `intended` / `wontfix`, `Resolved`): skill viết tiếng Anh, và `az` làm hỏng ký tự non-ASCII.
> - `conventions.md → ## Risk` chỉ giữ định nghĩa và bảng mức; ai đọc gì theo mức là quy ước team (mục *Quy ước team*), và `--pr` chưa tồn tại.
> - Câu README "không *tự* nhận mô tả tự do" giữ nguyên vì nó đúng; mục *Một vòng làm việc* đã khớp luồng hiện tại.
> - Báo cáo `verify` có thêm dòng `Round · Base · Head` để giai đoạn 3 biết vòng trước so trên commit nào.
> - Migrate của `init`: mục 8 đề nghị thêm dòng `Code standards:`; mục 9 chỉ in khối `sensitive:` (migrate không bao giờ sửa `config.yaml`). Chạy không người thì cả hai chỉ in ra.
> - Đã thử `/sk:init` (mới, và migrate không người) trên bản clone của `ics-viewer-editor`.

### 1.1 Tiêu chí rủi ro chung trong `reference/conventions.md`

Chuyển định nghĩa one-way / two-way door đang nằm trong `skills/pr/SKILL.md` (mục *Merge danger*) sang một mục mới `## Risk` trong `conventions.md`.

- **Two-way door:** chỉ thêm hành vi, revert được bằng commit hoặc tắt flag.
- **One-way door:** revert không gỡ được hậu quả — đổi schema, endpoint/event/tool mà hệ thống khác dùng, xóa requirement, dữ liệu ghi theo cấu trúc mới, dữ liệu đã gửi ra ngoài (ví dụ document EDI).
- **Blast radius:** actor và caller mà các Scenario nhắc tới, cộng các vùng trong diff.
- **Vùng nhạy cảm:** lấy từ `sk/config.yaml` (mục mới `sensitive`, xem 1.2), không hard-code trong kit.
- **Quy đổi ra mức:** theo bảng dưới đây; blast radius được tính vào khi quy ra mức.

| Mức | Điều kiện | Review sớm (draft PR) | Review PR |
| --- | --- | --- | --- |
| Thấp | Two-way, không chạm vùng nhạy cảm, chỉ ảnh hưởng nội bộ hoặc nằm sau flag | Không | Đọc spec và bằng chứng trên ADO |
| Trung bình | Two-way nhưng chạm vùng nhạy cảm, hoặc ảnh hưởng trực tiếp tới khách / trading partner | Đọc spec | `/sk:verify --pr`, tự đọc code vùng nhạy cảm |
| Cao | One-way door | Đọc spec và `design.md` | `/sk:verify --pr`, `/security-review`, cả hai người duyệt đọc kỹ |

**Khi không chắc thì xếp mức cao hơn.** Quy tắc này cố ý ngược với cách `verify` xếp phát hiện (“không chắc thì xếp thấp hơn”): xếp phát hiện cao nhầm gây nhiễu, còn xếp rủi ro thấp nhầm làm người review bỏ qua đúng chỗ cần đọc. Danh sách vùng nhạy cảm cụ thể cần team chốt (xem Câu hỏi mở).

`skills/pr/SKILL.md` sửa để tham chiếu mục này thay vì tự định nghĩa.

### 1.2 Một nguồn tiêu chuẩn code chung

- `templates/config.yaml`: trong `context`, thêm dòng mẫu trỏ tới file tiêu chuẩn (ví dụ `docs/code-standards.md`); thêm mục `sensitive:` liệt kê glob các đường dẫn nhạy cảm (auth, token, CI, dữ liệu khách).
- `skills/init/SKILL.md` (Step 5): đoạn append vào `CLAUDE.md` thêm một dòng trỏ tới cùng file tiêu chuẩn, để `/code-review` (chỉ đọc `CLAUDE.md`) thấy cùng bộ quy tắc với `verify`.
- `init` không tự tạo file tiêu chuẩn. Nếu repo chưa có, `init` báo lại và để trống dòng đó kèm comment nhắc, giống cách xử lý `ado.orgUrl`.
- Bước migrate của `init` (bảng các bước nâng cấp workspace cũ) thêm một dòng: workspace có `CLAUDE.md` thiếu dòng trỏ tiêu chuẩn → đề nghị append, không sửa đoạn cũ.

### 1.3 Mã phát hiện ổn định trong `verify`

- Mỗi phát hiện trong báo cáo mang mã `V<n>`, đánh số trên toàn báo cáo (không tách theo mức).
- `verify` nhận thêm đầu vào tùy chọn là báo cáo vòng trước (người dùng dán, hoặc đọc comment PR qua `az` khi có `--pr`, xem giai đoạn 3). Phát hiện vẫn còn giữ mã cũ; phát hiện mới lấy số tiếp theo; phát hiện đã hết hiển thị `đã hết` thay vì biến mất.
- Ghép phát hiện giữa hai vòng dựa trên file, Requirement/Scenario liên quan và loại lỗi; không chắc thì cấp mã mới và ghi "có thể là V\<n>".
- Báo cáo thêm cột *Xử lý* để trống cho tác giả điền: `đã sửa` / `sai` / `cố ý` / `không đáng sửa`.
- Báo cáo luôn thể hiện đầy đủ trạng thái hiện tại, để comment mới nhất trên PR là nguồn sự thật, và có định dạng sẵn để dán thành comment (một khối markdown).

### 1.4 Sửa README

- Mục *Những gì kit cố ý không làm*: bỏ câu "không nhận mô tả tự do", mô tả change dạng `req-` từ yêu cầu trực tiếp (đã có từ v0.11.0).
- Mục *Một vòng làm việc*: cập nhật theo luồng hiện tại (`propose` chỉ ghi `proposal.md`; `continue`/`ff` ghi spec, design, tasks).

### Tiêu chí hoàn thành giai đoạn 1

- [ ] Toàn bộ evals hiện có vẫn pass.
- [ ] Evals mới cho 1.3 pass (xem mục Evals).
- [ ] `pr` và `conventions.md` dùng chung một định nghĩa rủi ro, không còn bản riêng trong `pr`.
- [ ] Chạy `/sk:init` trên một repo thật của team và kiểm tra `git diff CLAUDE.md`.

## Giai đoạn 2 — Review sớm bằng draft PR

Giai đoạn này đưa sự chú ý của người review lên trước khi có code, cho các change rủi ro trung bình trở lên. Phát hành thành v0.14.0.

> **Trạng thái (2026-11-10): đã triển khai** cùng nhánh với giai đoạn 1 (PR #9). Khác với bản thảo, sau review:
> - `## Risk (preliminary)` có bốn dòng: Level, Door, Sensitive areas, Early review. Blast radius nằm ở `## Impact`.
> - Criteria còn `none yet` → Door ghi "chưa xác định được", Level và Early review để mở; thiếu criteria không phải là không chắc về door.
> - `continue` nâng mức khi proposal ghi bất cứ gì khác one-way (kể cả "chưa xác định"). `ff` dừng sau bước design (vẫn viết design nếu delta làm tăng rủi ro).
> - `/sk:pr` code review: mức preliminary `confirmed` không bao giờ bị hạ; `unconfirmed` thì ghi cả hai mức. Spec review khi proposal chưa có mục Risk → nói rõ và xếp mức từ spec.
> - Evidence chỉ nhắc dán báo cáo `verify` khi hội thoại đã có báo cáo đó; không đưa con số 4.000 ký tự vào body (tránh model chép số không có trong artifact).

**Draft PR không bị hook `pre-push` chặn.** Hook chỉ chặn một change đã tick **hết** task mà chưa archive, hoặc marker `[[OPEN:Q<n>]]` trong `sk/specs/`. Lúc tạo draft (spec review) chưa task nào được tick và delta còn nằm trong `sk/changes/`, nên push bình thường — không cần nới hook. Hook chỉ chặn ở mốc Publish; khi đó tác giả archive trước, và `verify --pr` đối chiếu với `sk/specs/` (3.3).

### 2.1 Mục *Risk (preliminary)* trong `proposal.md`

- `templates/proposal.md` thêm mục `## Risk (preliminary)` gồm bốn dòng: *Level*, *Door*, *Sensitive areas*, *Early review: yes | no*. *Blast radius* không lặp lại: nó đã nằm trong `## Impact` có sẵn của proposal; mục Risk trỏ tới đó.
- `skills/propose/SKILL.md`: điền mục này theo `conventions.md → ## Risk`, dựa trên AC, mô tả work item và mục `sensitive` trong `config.yaml`. Không đủ thông tin thì ghi lý do vào dòng đó, không đoán. Đây là **đề xuất**: mang nhãn `confirmed` / `unconfirmed` như `## Assumptions` và vào vòng hỏi của propose khi có người trả lời — nhờ vậy không mâu thuẫn với "kit không tự xếp rủi ro thay người".
- Mức trong proposal **chỉ được kit nâng, không bao giờ tự hạ**; hạ là việc của người.
- Chỉ `/sk:continue` (Step 3, khi viết `design.md`) giữ quy tắc: *Contracts* **đổi hoặc xóa** schema/interface đã có người dùng → nâng *Door* thành one-way và nói rõ trong câu trả lời. Interface mới chưa ai dùng vẫn là two-way — eval 0.13.0 cho thấy câu chữ mơ hồ ở đây khiến model xếp High cho một hàm export mới. `/sk:ff` không chép quy tắc này (nó đọc Step 3 của `continue` lúc chạy); chỉ thêm vào *Stop early* của `ff`: Door vừa chuyển one-way và Early review thành `yes` → dừng sau design. Việc `continue` sửa `proposal.md` đã có tiền lệ, không phá luật một artifact mỗi lần gọi.
- Khi *Early review* là `yes`, câu kết của `continue`/`ff` (sau khi có spec và design) nhắc: tạo draft PR và chạy `/sk:pr` trước khi `/sk:apply`.

### 2.2 `/sk:pr` có hai chế độ

**Nhận biết chế độ.** Diff so với nhánh mặc định chỉ chạm `sk/` và chưa task nào được tick → *spec review*; ngược lại → *code review*. Không có shell thì dựa vào checkbox trong `tasks.md` — chưa tick không chứng minh chưa có code, nên câu thông báo chế độ nêu giới hạn này. Thông báo `Mode: spec review | code review` và cách đổi bằng `--spec` / `--code`.

**Chế độ spec review** sinh các mục theo thứ tự:

| Mục | Nội dung |
| --- | --- |
| Summary | AB# + tiêu đề, 2–3 câu từ proposal |
| Review now | Đường dẫn spec delta và `design.md` (nếu có); câu hỏi cho người review; ghi rõ không cần đọc `tasks.md` |
| Spec changes | Như hiện tại |
| Contracts | Như hiện tại, khi có design |
| Gaps & assumptions | Từ proposal — những chỗ người review có thể trả lời |
| Risk (preliminary) | Chép từ proposal, ghi rõ là ước lượng trước khi có code |

Không có mục *Tasks*, *Evidence*, *Open before merge* trong chế độ này.

**Chế độ code review** giữ nguyên cấu trúc hiện tại, thêm ba điểm:

- *Merge danger* so với *Risk (preliminary)*: mức tăng thì ghi rõ "Rủi ro tăng từ X lên Y vì …" ở đầu mục.
- Dòng *Suggested tag* cuối mục *Merge danger* (`risk:low` / `risk:medium` / `risk:high`) để tác giả gắn trên ADO.
- *Evidence* nhắc dán báo cáo `verify` mới nhất thành comment riêng, thay vì chép vào mô tả (mô tả PR trên ADO giới hạn khoảng 4.000 ký tự).

**Vòng đời mô tả PR.** Chỉ viết ở hai mốc: lúc tạo draft (spec review) và lúc Publish (code review, thay toàn bộ một lần). Mọi cập nhật theo vòng đi vào comment. Ghi quy ước này vào README.

### Tiêu chí hoàn thành giai đoạn 2

- [ ] Evals `pr-*` hiện có pass ở chế độ code review.
- [ ] Ba eval mới cho chế độ spec review và so sánh rủi ro pass.
- [ ] Thử trọn một vòng draft PR → Publish trên một User Story thật có rủi ro trung bình.

## Giai đoạn 3 — Gộp code review vào `verify`

Sau giai đoạn này, một lệnh `/sk:verify` dùng được cho cả hai lần review: tác giả tự review và dev khác review PR. Phát hành thành v0.15.0; đây là giai đoạn lớn nhất.

### 3.1 Chiều thứ tư: *Code health*

- Thêm Step mới sau *Coherence*. Chạy trong một subagent với ngữ cảnh mới khi có tool `Agent`; subagent chỉ nhận diff, file tiêu chuẩn chung và mục `sensitive` — không nhận proposal, spec hay tasks. **Đường lui:** không có subagent → chạy ngay trong `verify` và ghi vào *Skipped*; không có diff (không shell) → đọc các file mà tasks và delta trỏ tới, nói rõ phạm vi bị thu hẹp. `docs/PLAN.md` từng xếp "subagent reviewer" ngoài phạm vi — cập nhật quyết định đó cùng lúc.
- Trọng tâm: lỗi logic, xử lý lỗi bị nuốt, null/biên, đồng thời, rò rỉ credential hoặc dữ liệu nhạy cảm qua log, thiếu kiểm tra quyền. Bỏ qua điều linter và type checker đã bắt.
- Bắt buộc `file:line` và bằng chứng đọc từ code, không đoán từ tên hàm.
- Phân mức: CRITICAL chỉ khi có bằng chứng cụ thể (lỗ hổng bảo mật, mất dữ liệu, crash có đường tái hiện); còn lại WARNING hoặc SUGGESTION. Giữ quy tắc "không chắc thì xếp thấp hơn".
- Gắn cờ theo loại lỗi: cùng một lỗi ở nhiều chỗ → một phát hiện liệt kê mọi vị trí.
- Lỗi có trước PR (nằm ngoài diff): nhãn `pre-existing`, tối đa SUGGESTION, không chặn archive.
- Báo cáo thêm dòng *Code health* trong bảng tổng và mục riêng `### Code health`, tách khỏi phát hiện theo spec.

### 3.2 Hội tụ qua nhiều vòng

- Khi có báo cáo vòng trước: vòng 3 trở đi chỉ review phần diff mới so với commit `Head` mà báo cáo vòng trước ghi (dòng `Round · Base · Head` có từ 0.13.0), không đăng lại phát hiện cũ còn mở (chỉ cập nhật trạng thái). `Head` là `not available` → review toàn bộ diff và nói rõ.
- Từ vòng thứ 4, dòng kết đề nghị dừng lại xem xét cách tiếp cận thay vì tiếp tục vòng sửa.
- Báo cáo ghi số vòng (`Round 2`) để đếm số vòng tới khi sạch.

### 3.3 Tham số `--pr <id>`

Đã chốt (2026-11-10): đọc ADO qua REST; `verify` không tự tạo worktree; đối chiếu với `sk/specs/` khi change đã archive.

1. **Đọc PR qua REST** (`_apis/git/repositories/{repo}/pullRequests/{id}`) kèm token như `/sk:propose`, theo `reference/azure-devops.md` — không dùng `az repos` hay `az devops invoke` (hỏng ký tự non-ASCII; `invoke` lỗi). Lấy nhánh nguồn, nhánh đích, mô tả; kiểm U+FFFD như khi đọc work item. Đây là lần đầu `verify` đọc ADO: sửa guardrail "No Azure DevOps access at all" thành "chỉ đọc PR và thread của PR qua REST, chỉ khi có `--pr`".
2. **`verify` không chạy `git fetch` hay `git worktree add`** — hai lệnh đó ghi vào `.git/` của repo làm việc. `/sk:verify --pr <id>` không kèm đường dẫn → in đúng các lệnh cần chạy (fetch nhánh nguồn, `git worktree add` vào thư mục cạnh repo) rồi dừng; người dùng chạy xong gọi `/sk:verify --pr <id> <đường-dẫn-worktree>`. Base của diff là nhánh đích của PR.
3. **Tìm chuẩn để đối chiếu**, theo thứ tự:
   - change mở trong `sk/changes/` của worktree (theo AB# trong mô tả hoặc tên nhánh);
   - không có — trường hợp bình thường, vì tác giả archive trước khi Publish và `archive/` bị gitignore → các requirement trong `sk/specs/` mà PR đã thêm hoặc sửa (`git diff <đích>...<nguồn> -- sk/specs`) làm chuẩn cho Completeness/Correctness; Coherence với `design.md` bỏ qua và ghi vào *Skipped*;
   - không có cả hai → chế độ 3.4.
4. Đọc thread của PR qua REST (`.../pullRequests/{id}/threads`) để tìm báo cáo `verify` gần nhất và giữ mã V\<n>; không đọc được thì nói rõ và đánh số từ đầu.
5. Chạy các bước như bình thường. **Lệnh test lấy từ `config.yaml` của nhánh đích, không phải của PR** — nếu không, tác giả PR quyết định lệnh nào chạy trên máy người review. PR có sửa `config.yaml` hoặc script test → hiện diff đó và hỏi trước khi chạy.
6. Kết thúc bằng lệnh xóa worktree để người dùng tự chạy.

**Vòng sửa của tác giả sau archive.** `verify` hiện bỏ qua `archive/`. Thêm: không có change mở cùng id → đọc `sk/changes/archive/<id>/` trên máy (như `/sk:pr`), để tác giả vẫn chạy các vòng sau khi đã archive.

Không cần sửa grader `no-write-outside-sk`: `verify` không còn tạo worktree.

### 3.4 Chạy khi không có change

Với PR refactor, sửa nóng, tech debt: `verify` chạy *Code health* và test, báo cáo ghi trong mục *Skipped* rằng Completeness, Correctness, Coherence đã bị bỏ qua vì không có change. Hiện tại `verify` dừng khi không tìm thấy change; hành vi này đổi thành hỏi một lần "chỉ chạy code health?" khi có người trả lời, hoặc tự chạy khi được gọi với `--pr`.

### 3.5 Nhắc `/security-review`

Khi diff chạm một glob trong `sensitive`, dòng kết của báo cáo nhắc chạy `/security-review`. `verify` không tự gọi lệnh này.

### Tiêu chí hoàn thành giai đoạn 3

- [ ] Evals `verify-*` hiện có pass.
- [ ] Ba eval mới (code health ×2, không có change) pass. `--pr` (cần REST và Bash) và giới hạn vòng (cần diff theo commit) không chạy được trong harness vì eval không có Bash → kiểm tay theo checklist, như đường `az` và lệnh move của archive.
- [ ] Chạy thử `/sk:verify --pr` trên 3–5 PR thật; đếm số phát hiện *Code health* mà tác giả đánh "sai" hoặc "không đáng sửa". Tỷ lệ cao thì sửa prompt trước khi phát hành.

## Giai đoạn 4 — Vòng lặp rút kinh nghiệm

Dữ liệu nằm trên Azure DevOps (comment PR, trạng thái thread, Bug có tag `escaped`); kit chỉ đọc và đề xuất. Bắt đầu sau khi giai đoạn 1–3 đã chạy ít nhất một tháng, để có dữ liệu thật.

### 4.1 `propose` cho Bug hỏi thêm hai câu

- Khi work item là Bug, `propose` hỏi: change hoặc PR nào đã gây ra lỗi, và lẽ ra lớp nào phải bắt được (`spec` | `design` | `standards` | `lint` | `test` | `verify` | `human review`). Câu trả lời "chưa biết" được chấp nhận.
- Ghi vào `proposal.md` mục mới `## Escape` (hai dòng). `/sk:pr` đưa mục này vào mô tả PR sửa lỗi.
- Câu trả lời của `propose` nhắc người dùng gắn tag `escaped` và link PR gây lỗi trên Bug — kit không tự gắn.

### 4.2 Skill mới `/sk:learn`

Mục đích: biến dữ liệu review thành thay đổi ở nguồn, có người duyệt.

1. **Đọc** (qua REST kèm token, chỉ đọc — không dùng `az`) trong một khoảng thời gian, mặc định 30 ngày: PR đã merge, comment báo cáo `verify` cuối cùng của mỗi PR, trạng thái thread, và Bug có tag `escaped`.
2. **Tổng hợp:** số vòng tới khi sạch, tỷ lệ phát hiện theo cách xử lý, loại phát hiện lặp lại từ 3 lần, lỗi lọt qua theo lớp bỏ sót.
3. **Đề xuất sửa ở nguồn** dưới dạng diff, theo thứ tự ưu tiên: lint/analyzer → file tiêu chuẩn → `rules` trong `config.yaml` → prompt của kit. Kèm đề xuất xóa quy tắc gây nhiều phát hiện "sai".
4. **Đề xuất case eval** từ mỗi lỗi lọt qua có lớp bỏ sót là `verify`: phác `prompt.md`, `fixture.sh` tối giản và grader — **chỉ in ra dạng văn bản**, vì eval thuộc repo plugin chứ không thuộc repo đang chạy `/sk:learn`. Không đưa dữ liệu khách, payload EDI hay credential vào fixture.
5. **Dừng chờ duyệt.** Chỉ ghi file sau khi người dùng đồng ý từng đề xuất, giống cách `archive` hỏi trước khi viết ADR.

Không lưu nhật ký trong repo. Nếu sau vài tháng việc đọc từ ADO quá chậm hoặc comment không theo mẫu, xem lại quyết định này.

### Tiêu chí hoàn thành giai đoạn 4

- [ ] Eval cho `propose` Bug ghi mục *Escape* và chấp nhận "chưa biết".
- [ ] Eval cho `learn` không ghi file khi chưa được duyệt.
- [ ] Chạy `/sk:learn` trong buổi họp tháng đầu tiên và áp dụng ít nhất một đề xuất.

## Evals cần thêm

Mười lăm case mới, theo đúng cấu trúc `evals/<case>/` hiện có (`case.yaml`, `fixture.sh`, `prompt.md`, `graders/`). Mỗi giai đoạn chỉ phát hành khi case của nó và toàn bộ case cũ đều pass.

| Giai đoạn | Case | Grader chính |
| --- | --- | --- |
| 1 ✅ | `verify-assigns-stable-ids` | Mỗi phát hiện có mã V\<n>; báo cáo có bảng Disposition để trống |
| 1 ✅ | `verify-keeps-ids-across-rounds` | Phát hiện còn lại giữ mã cũ; phát hiện mới lấy số tiếp; phát hiện đã sửa nằm trong *Resolved*; báo cáo ghi Round 2 |
| 1 ✅ | `init-points-claude-md-at-standards` | `CLAUDE.md` có dòng `Code standards:`; nội dung cũ không đổi; `config.yaml` có `sensitive:` |
| 2 | `propose-writes-preliminary-risk` | `proposal.md` có mục Risk đủ bốn dòng; change chạm vùng `sensitive` được xếp trung bình trở lên |
| 2 | `pr-spec-mode-omits-tasks` | Chế độ spec review: không có Tasks, Evidence, Open before merge; có Review now |
| 2 | `pr-spec-mode-risk-from-proposal` | Risk lấy từ proposal và ghi là ước lượng |
| 2 | `pr-flags-risk-increase` | Chế độ code review: diff đổi schema trong khi proposal ghi two-way → báo rủi ro tăng |
| 3 | `verify-catches-unspecified-bug` | Bắt được lỗi thật mà spec không nhắc tới, đúng file và dòng |
| 3 | `verify-clean-code-no-invented-findings` | Code sạch: mục Code health trống hoặc chỉ SUGGESTION |
| 3 (tay) | `verify-pr-uses-worktree` | Kiểm tay: `--pr` không kèm đường dẫn chỉ in lệnh; với đường dẫn: base là nhánh đích, lệnh test từ nhánh đích, không ghi gì |
| 3 | `verify-no-change-runs-code-health` | Không có change: chạy Code health, liệt kê các chiều bị bỏ qua |
| 3 (tay) | `verify-round-cap-suggests-rethink` | Vòng 4: chỉ review diff mới, không lặp phát hiện cũ, đề nghị xem lại cách tiếp cận |
| 4 | `propose-bug-records-escape` | Mục Escape được ghi; "chưa biết" được chấp nhận |
| 4 | `learn-proposes-without-writing` | Đề xuất dạng diff; không file nào bị ghi trước khi duyệt (fixture JSON offline cho PR, thread, Bug — như `work-item-<id>.json`) |
| 4 | `learn-drafts-eval-from-escape` | Lỗi lọt qua ở lớp verify → có phác thảo case eval, không chứa dữ liệu nhạy cảm |

Không cần nới grader `no-write-outside-sk`: `verify` không tạo worktree (3.3). Hai case đánh dấu *(tay)* không chạy được trong harness (không có Bash) và nằm trong checklist kiểm tay. Case `verify-catches-unspecified-bug` và `verify-clean-code-no-invented-findings` nên chạy nhiều lần mỗi lượt đánh giá (ví dụ 5 lần) vì kết quả của chúng dao động nhiều nhất.

## Quy ước team và cấu hình Azure DevOps

Những việc này nằm ngoài kit, nên làm song song với giai đoạn 1 vì chúng không phụ thuộc code.

**Branch policy cho nhánh chính**

| Policy | Mục đích |
| --- | --- |
| Build validation | CI (build, test, analyzer) phải xanh mới merge |
| Check for comment resolution | Thread còn *Active* thì không merge được |
| Automatically included reviewers theo path | Vùng nhạy cảm (khớp mục `sensitive`) luôn có người duyệt bắt buộc |
| Reset approval votes khi có push mới | Mỗi approval chỉ có hiệu lực cho một commit |

**Hai lần review**

- *Tác giả tự review:* chạy `/sk:verify` (và `/security-review` khi được nhắc) cho tới khi không còn CRITICAL; dán báo cáo thành comment đầu tiên khi Publish; gắn tag rủi ro theo *Suggested tag*.
- *Dev khác review PR:* kiểm tra lại tag rủi ro trước tiên; rủi ro thấp → đọc spec delta và bằng chứng trên ADO; trung bình trở lên → `/sk:verify --pr <id>`; luôn tự đọc code ở vùng nhạy cảm và thay đổi kiến trúc.
- *Ghi cách xử lý:* nguồn chính là cột *Disposition* trong báo cáo `verify` cuối cùng (`fixed` / `wrong` / `intended` / `wontfix`). Phát hiện từ WARNING trở lên vẫn tách thành thread riêng; trạng thái thread (*Fixed*, *By Design*, *Won't Fix*) chỉ dùng để đối chiếu — trên ADO *Closed* là trạng thái đóng chung chung, không có nghĩa là "sai", nên không dùng nó để đếm nhiễu.

**Số người duyệt theo rủi ro.** Hiện team yêu cầu hai người cho mọi PR. Giữ nguyên trong ba tháng đầu. Sau đó, nếu số lỗi lọt qua không tăng, cân nhắc giảm xuống một người cho PR `risk:low`.

**Lỗi lọt qua.** Bug do một PR đã merge gây ra → tag `escaped`, link tới PR đó, một comment ghi lớp bỏ sót.

**Họp tháng (30 phút).** Xem lại Bug `escaped`, phát hiện bị đánh *Closed* nhiều nhất, góp ý lặp lại từ 3 lần; từ giai đoạn 4 trở đi, chạy `/sk:learn` trong buổi này.

## Phát hành, đo lường và rủi ro

**Phát hành.** Mỗi giai đoạn là một phiên bản minor (v0.13.0 → v0.16.0), có release note trong `docs/release-notes/` và dòng trong `CHANGELOG.md`. Vì plugin không tự cập nhật, mỗi bản cần thông báo cho team kèm lệnh `/plugin update sk@simplify`. Thử mỗi bản trên một repo và một hoặc hai người trước khi báo cả team.

**Đo lường.** Ghi mốc trước khi bắt đầu giai đoạn 1, rồi đo lại hàng tháng.

| Chỉ số | Nguồn | Hướng mong muốn |
| --- | --- | --- |
| Bug `escaped` mỗi tháng | WIQL trên ADO | Không tăng (lan can bảo vệ) |
| Số vòng `verify` tới khi sạch | Số *Round* trong comment cuối | Giảm |
| Tỷ lệ phát hiện *Closed* + *Won't Fix* | Trạng thái thread | Giảm (ít nhiễu hơn) |
| Thời gian PR chờ người review | Ngày Publish đến ngày approval | Giảm |
| Tỷ lệ PR rủi ro trung bình trở lên có review spec sớm | Draft PR có comment trước khi có code | Tăng |

**Rủi ro của kế hoạch**

| Rủi ro | Cách giảm |
| --- | --- |
| *Code health* gây nhiễu, dev bỏ qua báo cáo | Eval code sạch; thử trên 3–5 PR trước khi phát hành; quy tắc "không chắc thì xếp thấp" |
| Tác giả tự gắn rủi ro thấp cho thay đổi nhạy cảm | Mục `sensitive` trong config; người review kiểm tra tag trước tiên; reviewer tự động theo path |
| Ghép mã V\<n> sai giữa các vòng | Không chắc thì cấp mã mới và ghi "có thể là V\<n>"; eval riêng |
| Đọc thread PR qua REST thất bại hoặc token thiếu quyền | `--pr` vẫn chạy khi không đọc được, chỉ đánh số lại từ đầu và nói rõ |
| Draft PR thành thêm thủ tục cho change nhỏ | Chỉ bật khi *Early review: yes*; change rủi ro thấp bỏ qua |

**Câu hỏi mở**

- [x] **Tên file tiêu chuẩn:** `docs/code-standards.md`. Repo đã có file khác thì giữ file đó — `init` lấy đường dẫn từ `context`, không ép tên.
- [x] **`sensitive:` mặc định đề xuất cho repo của team** (điền tay khi chạy `init`, chỉnh theo từng repo):
  ```yaml
  sensitive:
    - "**/Auth/**"                 # đăng nhập, phân quyền
    - "**/*Token*"                 # token, credential
    - "**/appsettings*.json"       # cấu hình chứa connection string
    - "azure-pipelines*.yml"       # CI/CD
    - ".azure-pipelines/**"
    - "**/Migrations/**"           # đổi schema — luôn one-way
    - "**/Edi/**"                  # dữ liệu gửi trading partner
  ```
- [ ] Ai là người duyệt bắt buộc cho từng vùng nhạy cảm trên ADO? (cần team chốt — không đặt được từ repo kit)
- [x] **Ngưỡng nhiễu:** trong một tháng có ít nhất 20 phát hiện *Code health*, nếu trên 30% bị đánh `wrong` hoặc `wontfix` thì sửa prompt trước khi làm thêm việc khác; dưới 20 phát hiện thì chưa kết luận.

## Những gì cố ý không làm

- **Không ghi lên ADO.** Không tạo PR, comment, thread hay tag từ kit; người dùng dán văn bản kit xuất ra.
- **Không tạo skill `/sk:review` riêng.** Review PR của người khác dùng `/sk:verify --pr`.
- **Không lưu nhật ký review trong repo** (`sk/review/`). Dữ liệu nằm trên comment PR và Bug; chỉ xem lại nếu sau vài tháng việc ghi chép không đều hoặc khó tổng hợp.
- **Không sửa mô tả PR theo từng vòng.** Chỉ viết ở hai mốc: draft và Publish.
- **Không tự xếp mức rủi ro thay người.** Kit đề xuất tag; tác giả gắn, người review xác nhận.
- **Không chạy Claude Code trong Azure Pipelines** cho tới khi tổ chức đồng ý về chi phí API và việc gửi code ra ngoài.
- **Không thay `/security-review`.** *Code health* bổ sung, không thay thế; vùng nhạy cảm vẫn chạy `/security-review`.
