# SimplifyKit (`sk`)

Bộ lệnh cho Claude Code giúp bạn đi từ **một User Story trên Azure DevOps** đến code đã xong, mà không phải viết lại yêu cầu lần thứ hai.

Bạn đưa nó mã work item. Nó đọc acceptance criteria từ board, viết ra bản đặc tả và danh sách việc cần làm, bạn xem lại, rồi nó làm. Những gì nó viết ra đều là file markdown nằm trong repo — review được trên PR như mọi thay đổi khác.

## Cài đặt

Chạy một lần trên máy bạn:

```
/plugin marketplace add thanhsang95/Simplify-Kit
/plugin install sk@simplify
```

Kiểm tra plugin đã bật:

```bash
claude plugin list          # tìm dòng: sk@simplify … Status: enabled
```

Nếu thấy `disabled` thì bật lên — lúc đang tắt, các lệnh `/sk:*` sẽ không xuất hiện:

```bash
claude plugin enable sk@simplify
```

Sau đó, mỗi repo làm một lần:

```
/sk:init
```

Lệnh này tạo thư mục `sk/` và ghi `sk/config.yaml` mô tả dự án. Xem qua file đó một lượt — nó là thứ Claude đọc mỗi lần làm việc, nên nếu có chỗ nào tả sai dự án thì sửa ngay lúc này.

## Một vòng làm việc

Giả sử bạn được giao User Story **12345**.

### 1. Lập kế hoạch

```
/sk:propose AB#12345
```

Nó đọc work item, dịch acceptance criteria thành đặc tả, và tạo ra:

```
sk/changes/us-12345-<tên-ngắn>/
  proposal.md      tóm tắt + giả định + những chỗ chưa rõ
  specs/<nhóm>/spec.md   đặc tả: hệ thống phải làm gì
  tasks.md         danh sách việc cần làm
  design.md        chỉ có khi thực sự cần chọn giữa các phương án kỹ thuật
```

**Bước này không sửa một dòng code nào.** Kể cả khi bạn bảo "làm luôn đi", nó vẫn chỉ lập kế hoạch rồi dừng. Đó là chủ ý: bạn xem kế hoạch trước khi code được viết.

### 2. Bạn đọc lại

Đây là lúc rẻ nhất để sửa. Mở `specs/<nhóm>/spec.md` và đọc như thể bạn là người nghiệm thu:

- Có scenario nào sai ý không?
- Có yêu cầu nào trong US mà đặc tả bỏ sót không?
- Có scenario nào *không* có trong US — tức nó tự nghĩ ra?

Xem luôn mục **Gaps** trong `proposal.md`: đó là những chỗ nó thấy AC chưa đủ rõ. Sửa thẳng vào file, hoặc nói cho nó sửa.

### 3. Làm

```
/sk:apply us-12345-<tên-ngắn>
```

Nó làm từng task, tick `- [x]` khi xong. Nó sẽ **dừng lại hỏi** nếu task mơ hồ, nếu phát hiện lỗ hổng trong kế hoạch, hoặc nếu việc cần làm vượt quá những gì đặc tả mô tả — thay vì tự quyết rồi làm tắt.

Xong thì chạy build/test của dự án như bình thường.

### 4. Đóng lại

```
/sk:archive us-12345-<tên-ngắn>
```

Yêu cầu từ change này được gộp vào `sk/specs/` — bản đặc tả chung của hệ thống — và change được chuyển vào `sk/changes/archive/`.

Bước này quan trọng hơn vẻ ngoài: `sk/specs/` là thứ lần sau Claude đọc để biết **hệ thống hiện đang phải thoả những gì**. Không archive thì lần sau nó làm việc trong tình trạng mất trí nhớ.

## Các file trong `sk/` nghĩa là gì

| Đường dẫn | Nội dung |
|---|---|
| `sk/config.yaml` | Mô tả dự án cho Claude: stack, lệnh build/test, tài liệu nên đọc, thông tin ADO |
| `sk/specs/<nhóm>/spec.md` | **Đặc tả đang hiệu lực** — hệ thống hôm nay phải làm gì. Tích luỹ qua nhiều story |
| `sk/changes/<id>/` | Một thay đổi đang làm dở |
| `sk/changes/archive/<id>/` | Thay đổi đã xong |

Trong đặc tả, mỗi yêu cầu viết thế này:

```markdown
### Requirement: Bộ chọn trường có kèm thuộc tính sản phẩm

Bộ chọn trường SHALL cho chọn các thuộc tính do hệ thống định nghĩa,
bên cạnh những trường chuẩn.

#### Scenario: Thuộc tính hiển thị thành nhóm riêng

- **WHEN** người quản trị mở bộ chọn trường
- **THEN** các thuộc tính SHALL nằm dưới một nhãn nhóm riêng
```

Đọc từ trên xuống: *Requirement* là cam kết, *Scenario* là điều kiểm chứng được.

## Khi nào nó sẽ hỏi bạn

Kit được thiết kế để **dừng lại hỏi** thay vì đoán. Vài tình huống hay gặp:

**"Work item này không có acceptance criteria."**
Khoảng 1/5 số User Story rơi vào đây. Nó sẽ đưa ra những gì lấy được (tiêu đề, mô tả, comment) rồi hỏi tiêu chí nghiệm thu. Nó **không** tự bịa ra đặc tả từ một ô trống — nếu bạn thấy nó làm vậy, đó là lỗi, báo lại.

**"Tiêu chí này tôi chưa chuyển thành hành vi quan sát được."**
Một AC viết chung chung quá thì nó đưa vào mục Gaps và hỏi, thay vì nặn thành scenario cho đủ số.

**"Hai thay đổi đang mâu thuẫn nhau."**
Khi `/sk:archive` thấy hai change cùng sửa một yêu cầu theo hai hướng, nó dừng và đưa cả hai phía cho bạn quyết. Nó không tự hoà giải, vì không có cách nào biết cái nào mới hơn.

**"Hãy archive change kia trước."**
Không phải lỗi — chỉ là thứ tự. Change này dựa trên yêu cầu mà change kia tạo ra.

## Có một quy tắc bạn cần nhớ

Nếu bạn **tự tay sửa** file spec delta trong `sk/changes/<id>/specs/`, và phần đó nằm dưới `## MODIFIED Requirements`:

> Phải giữ lại **toàn bộ** requirement, kể cả những scenario bạn không đụng tới.

Vì lúc archive, requirement cũ trong `sk/specs/` bị thay nguyên khối bằng bản trong delta. Xoá bớt scenario ở đây đồng nghĩa xoá chúng khỏi đặc tả chung — mà không có cảnh báo nào, vì tên vẫn khớp.

Cách an toàn: copy nguyên requirement từ `sk/specs/` sang rồi sửa trên bản copy. (`/sk:archive` có kiểm nếu số scenario giảm đi, nhưng đừng dựa vào đó.)

## Những gì kit cố ý không làm

- **Không sửa code ở bước `propose`** — kể cả khi bạn yêu cầu trong cùng câu lệnh
- **Không ghi gì lên Azure DevOps** — không comment, không tạo Task, không đổi state. Cập nhật board vẫn là việc của bạn
- **Không nhận mô tả tự do** — `/sk:propose` cần `AB#<id>` hoặc URL work item. Việc không có work item (refactor, tech debt, spike) thì dùng cách bạn vẫn làm
- **Không nhận số trần** — `12345` là mơ hồ, vì trong repo này số trần đã mang nghĩa mã PR. Gõ `AB#12345`

## Gỡ rối

| Hiện tượng | Xử lý |
|---|---|
| Không thấy lệnh `/sk:*` nào | Plugin đang tắt: `claude plugin list` rồi `claude plugin enable sk@simplify` |
| `/sk:propose` bảo chạy `/sk:init` trước | Repo chưa có `sk/`. Chạy `/sk:init`. Kit cố ý không tự tạo `sk/` |
| Nó hỏi lại thay vì viết đặc tả | Work item thiếu acceptance criteria. Đây là hành vi đúng |
| Nó báo lỗi khi đọc work item | Kiểm `az login`, và `ado.orgUrl` trong `sk/config.yaml` có đúng URL đầy đủ không |
| `/sk:archive` dừng giữa chừng | Nó phát hiện xung đột và đang chờ bạn quyết. Đọc thông báo — nó nói rõ requirement nào |

## Muốn sửa chính bộ kit này?

Xem `CONTRIBUTING.md` — cấu trúc plugin, cách chạy bộ eval, và những ràng buộc môi trường cần biết trước khi sửa.
