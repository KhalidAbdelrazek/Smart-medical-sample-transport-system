#define REG_SIZE       8
#define SET_BIT(reg,bit)     (reg|=(1<<bit))
#define CLR_BIT(reg,bit)     (reg&=(~(1<<bit)))
#define TOG_BIT(reg,bit)     (reg^=(1<<bit))
#define READ_BIT(reg,bit)    ((reg&(1u<<bit))>>bit)
#define ROL(reg,number)      (reg=((reg<<number)|(reg>>(REG_SIZE-number))))
#define ROR(reg,number)      (reg=((reg>>number)|(reg<<(REG_SIZE-number))))

