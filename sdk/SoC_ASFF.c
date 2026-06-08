#include "xparameters.h"
#include "xaxidma.h"
#include "xil_cache.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "ff.h"

#define MY_IP_BASE          XPAR_ASFF_2_IP_0_S00_AXI_BASEADDR
#define REG_CTRL            (MY_IP_BASE + 0)
#define REG_SIZE            (MY_IP_BASE + 4)
#define REG_CHANNEL         (MY_IP_BASE + 8)
#define REG_COM_CHANNEL     (MY_IP_BASE + 12)
#define REG_STATUS          (MY_IP_BASE + 16)

#define DMA_DEV_ID          XPAR_AXI_DMA_0_DEVICE_ID

#define MAX_ELEMENTS        8192
#define MAX_DATA_LEN        (MAX_ELEMENTS * sizeof(u32))
#define TIMEOUT_LIMIT       10000000

XAxiDma myDma;
FATFS fatfs;
FIL fil;

u32 TxBuffer[MAX_ELEMENTS] __attribute__((aligned(64)));
u32 RxBuffer[MAX_ELEMENTS] __attribute__((aligned(64)));

int main() {
    int status;
    FRESULT res;
    UINT bytes_read;
    u32 ip_status;
    int timeout;
    UINT bytes_written;
    FRESULT res_write;

    xil_printf("\r\n--- START SYSTEM ---\r\n");

    // Init DMA
    XAxiDma_Config *myDMAConfig = XAxiDma_LookupConfig(DMA_DEV_ID);
    status = XAxiDma_CfgInitialize(&myDma, myDMAConfig);
    if (status != XST_SUCCESS) {
        xil_printf("Loi: Khoi tao DMA that bai!\r\n");
        return -1;
    }
    xil_printf("OK: Khoi tao DMA thanh cong!\r\n");

    // Reset IP
//    Xil_Out32(REG_CTRL, 0);

    // Read SD Card
    res = f_mount(&fatfs, "0:/", 1);
    if (res != FR_OK) return -1;
    res = f_open(&fil, "DATAFM.BIN", FA_READ);
    if (res != FR_OK) return -1;
    res = f_read(&fil, (void*)TxBuffer, MAX_DATA_LEN, &bytes_read);
    f_close(&fil);

    if (bytes_read == 0) {
        xil_printf("Loi: File rong hoac doc loi!\r\n");
        return -1;
    }

    u32 rx_bytes = 28672;

    xil_printf("Doc duoc %d bytes tu the SD\r\n", bytes_read);

    Xil_DCacheFlushRange((UINTPTR)TxBuffer, bytes_read);

    XAxiDma_Reset(&myDma);
    while (!XAxiDma_ResetIsDone(&myDma));

    status = XAxiDma_SimpleTransfer(&myDma, (UINTPTR)RxBuffer, rx_bytes, XAXIDMA_DEVICE_TO_DMA);
    status |= XAxiDma_SimpleTransfer(&myDma, (UINTPTR)TxBuffer, bytes_read, XAXIDMA_DMA_TO_DEVICE);

    if (status != XST_SUCCESS) {
        xil_printf("Loi: Truyen DMA that bai!\r\n");
        return -1;
    }

    Xil_Out32(REG_SIZE, 8);
    Xil_Out32(REG_CHANNEL, 4);
    Xil_Out32(REG_COM_CHANNEL, 2);

    Xil_Out32(REG_CTRL, 2);
    Xil_Out32(REG_CTRL, 3);
    xil_printf("DMA dang chay, IP bat dau...\r\n");


    timeout = TIMEOUT_LIMIT;
    do {
        ip_status = Xil_In32(REG_STATUS);
        timeout--;
    } while (((ip_status & 0x01) == 0) && (timeout > 0));

    if (timeout <= 0) {
        xil_printf("Loi: IP TIMEOUT! Khong co phan hoi hoan thanh.\r\n");
        return -1;
    }

    Xil_DCacheInvalidateRange((UINTPTR)RxBuffer, rx_bytes);

    xil_printf("DMA & IP XU LY THANH CONG\r\n");

    xil_printf("In 10 gia tri dau\r\n");
    int elements_to_print = (rx_bytes / 4 > 10) ? 10 : (rx_bytes / 4);
    for (int i = 0; i < elements_to_print; i += 2) {
        if (i + 1 < elements_to_print) {
            xil_printf("Data[%d] = 0x%08X    |    Data[%d] = 0x%08X\r\n", i, RxBuffer[i], i + 1, RxBuffer[i + 1]);
        } else {
            xil_printf("Data[%d] = 0x%08X\r\n", i, RxBuffer[i]);
        }
    }

    int total_elements = rx_bytes / 4;
    int start_index = (total_elements > 10) ? (total_elements - 10) : 0;

    xil_printf("In 10 gia tri cuoi\r\n");
    for (int i = start_index; i < total_elements; i += 2) {
        if (i + 1 < total_elements) {
            xil_printf("Data[%d] = 0x%08X    |    Data[%d] = 0x%08X\r\n", i, RxBuffer[i], i + 1, RxBuffer[i + 1]);
        } else {
            xil_printf("Data[%d] = 0x%08X\r\n", i, RxBuffer[i]);
        }
    }

    res_write = f_open(&fil, "RESULT.BIN", FA_WRITE | FA_CREATE_ALWAYS);
    if (res_write != FR_OK) {
        xil_printf("Loi tao file RESULT.BIN: %d\r\n", res_write);
    } else {
        res_write = f_write(&fil, (const void*)RxBuffer, rx_bytes, &bytes_written);
        if (res_write != FR_OK) {
           xil_printf("Loi ghi the SD: %d\r\n", res_write);
        } else if (bytes_written != rx_bytes) {
            xil_printf("Loi thieu du lieu: %d / %d\r\n", bytes_written, rx_bytes);
        } else {
            xil_printf("Da luu %d bytes vao RESULT.BIN.\r\n", bytes_written);
        }
        f_close(&fil);
    }

    return 0;
}
